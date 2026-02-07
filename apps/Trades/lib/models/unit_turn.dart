// Property Management Models — Unit Turns
// Maps to `unit_turns` and `unit_turn_tasks` tables in Supabase PostgreSQL.
// Manages the turnover process between tenants (move-out to move-in ready).

enum TurnStatus {
  pending,
  inProgress,
  ready,
  listed,
  leased,
}

enum TurnTaskType {
  cleaning,
  painting,
  flooring,
  appliance,
  plumbing,
  electrical,
  hvac,
  general,
  inspection,
  keys,
}

enum TurnTaskStatus {
  pending,
  inProgress,
  completed,
  skipped,
}

class UnitTurn {
  final String id;
  final String companyId;
  final String propertyId;
  final String unitId;
  final String? outgoingLeaseId;
  final String? incomingLeaseId;
  final DateTime? moveOutDate;
  final DateTime? targetReadyDate;
  final DateTime? actualReadyDate;
  final String? moveOutInspectionId;
  final String? moveInInspectionId;
  final double? totalCost;
  final double? depositDeductions;
  final TurnStatus status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<UnitTurnTask> tasks;

  const UnitTurn({
    this.id = '',
    this.companyId = '',
    this.propertyId = '',
    this.unitId = '',
    this.outgoingLeaseId,
    this.incomingLeaseId,
    this.moveOutDate,
    this.targetReadyDate,
    this.actualReadyDate,
    this.moveOutInspectionId,
    this.moveInInspectionId,
    this.totalCost,
    this.depositDeductions,
    this.status = TurnStatus.pending,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.tasks = const [],
  });

  Map<String, dynamic> toInsertJson() => {
        'company_id': companyId,
        'property_id': propertyId,
        'unit_id': unitId,
        if (outgoingLeaseId != null) 'outgoing_lease_id': outgoingLeaseId,
        if (incomingLeaseId != null) 'incoming_lease_id': incomingLeaseId,
        if (moveOutDate != null)
          'move_out_date': moveOutDate!.toUtc().toIso8601String(),
        if (targetReadyDate != null)
          'target_ready_date': targetReadyDate!.toUtc().toIso8601String(),
        if (actualReadyDate != null)
          'actual_ready_date': actualReadyDate!.toUtc().toIso8601String(),
        if (moveOutInspectionId != null)
          'move_out_inspection_id': moveOutInspectionId,
        if (moveInInspectionId != null)
          'move_in_inspection_id': moveInInspectionId,
        if (totalCost != null) 'total_cost': totalCost,
        if (depositDeductions != null)
          'deposit_deductions': depositDeductions,
        'status': _enumToDb(status),
        if (notes != null) 'notes': notes,
      };

  Map<String, dynamic> toUpdateJson() => {
        'outgoing_lease_id': outgoingLeaseId,
        'incoming_lease_id': incomingLeaseId,
        'move_out_date': moveOutDate?.toUtc().toIso8601String(),
        'target_ready_date': targetReadyDate?.toUtc().toIso8601String(),
        'actual_ready_date': actualReadyDate?.toUtc().toIso8601String(),
        'move_out_inspection_id': moveOutInspectionId,
        'move_in_inspection_id': moveInInspectionId,
        'total_cost': totalCost,
        'deposit_deductions': depositDeductions,
        'status': _enumToDb(status),
        'notes': notes,
      };

  factory UnitTurn.fromJson(Map<String, dynamic> json) {
    return UnitTurn(
      id: json['id'] as String? ?? '',
      companyId:
          (json['company_id'] ?? json['companyId']) as String? ?? '',
      propertyId:
          (json['property_id'] ?? json['propertyId']) as String? ?? '',
      unitId: (json['unit_id'] ?? json['unitId']) as String? ?? '',
      outgoingLeaseId:
          (json['outgoing_lease_id'] ?? json['outgoingLeaseId'])
              as String?,
      incomingLeaseId:
          (json['incoming_lease_id'] ?? json['incomingLeaseId'])
              as String?,
      moveOutDate: _parseDate(
          json['move_out_date'] ?? json['moveOutDate']),
      targetReadyDate: _parseDate(
          json['target_ready_date'] ?? json['targetReadyDate']),
      actualReadyDate: _parseDate(
          json['actual_ready_date'] ?? json['actualReadyDate']),
      moveOutInspectionId:
          (json['move_out_inspection_id'] ?? json['moveOutInspectionId'])
              as String?,
      moveInInspectionId:
          (json['move_in_inspection_id'] ?? json['moveInInspectionId'])
              as String?,
      totalCost:
          (json['total_cost'] ?? json['totalCost'] as num?)?.toDouble(),
      depositDeductions:
          (json['deposit_deductions'] ?? json['depositDeductions'] as num?)
              ?.toDouble(),
      status: _parseEnum(
        json['status'] as String?,
        TurnStatus.values,
        TurnStatus.pending,
      ),
      notes: json['notes'] as String?,
      createdAt:
          _parseDate(json['created_at'] ?? json['createdAt']) ??
              DateTime.now(),
      updatedAt:
          _parseDate(json['updated_at'] ?? json['updatedAt']) ??
              DateTime.now(),
      tasks: (json['tasks'] as List<dynamic>?)
              ?.map((e) =>
                  UnitTurnTask.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  UnitTurn copyWith({
    String? id,
    String? companyId,
    String? propertyId,
    String? unitId,
    String? outgoingLeaseId,
    String? incomingLeaseId,
    DateTime? moveOutDate,
    DateTime? targetReadyDate,
    DateTime? actualReadyDate,
    String? moveOutInspectionId,
    String? moveInInspectionId,
    double? totalCost,
    double? depositDeductions,
    TurnStatus? status,
    String? notes,
    List<UnitTurnTask>? tasks,
  }) {
    return UnitTurn(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      propertyId: propertyId ?? this.propertyId,
      unitId: unitId ?? this.unitId,
      outgoingLeaseId: outgoingLeaseId ?? this.outgoingLeaseId,
      incomingLeaseId: incomingLeaseId ?? this.incomingLeaseId,
      moveOutDate: moveOutDate ?? this.moveOutDate,
      targetReadyDate: targetReadyDate ?? this.targetReadyDate,
      actualReadyDate: actualReadyDate ?? this.actualReadyDate,
      moveOutInspectionId:
          moveOutInspectionId ?? this.moveOutInspectionId,
      moveInInspectionId:
          moveInInspectionId ?? this.moveInInspectionId,
      totalCost: totalCost ?? this.totalCost,
      depositDeductions: depositDeductions ?? this.depositDeductions,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
      tasks: tasks ?? this.tasks,
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

class UnitTurnTask {
  final String id;
  final String unitTurnId;
  final TurnTaskType taskType;
  final String? description;
  final String? assignedTo;
  final String? vendorId;
  final double? estimatedCost;
  final double? actualCost;
  final TurnTaskStatus status;
  final DateTime? completedAt;
  final String? jobId;
  final String? notes;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UnitTurnTask({
    this.id = '',
    this.unitTurnId = '',
    this.taskType = TurnTaskType.general,
    this.description,
    this.assignedTo,
    this.vendorId,
    this.estimatedCost,
    this.actualCost,
    this.status = TurnTaskStatus.pending,
    this.completedAt,
    this.jobId,
    this.notes,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toInsertJson() => {
        'unit_turn_id': unitTurnId,
        'task_type': UnitTurn._enumToDb(taskType),
        if (description != null) 'description': description,
        if (assignedTo != null) 'assigned_to': assignedTo,
        if (vendorId != null) 'vendor_id': vendorId,
        if (estimatedCost != null) 'estimated_cost': estimatedCost,
        if (actualCost != null) 'actual_cost': actualCost,
        'status': UnitTurn._enumToDb(status),
        if (completedAt != null)
          'completed_at': completedAt!.toUtc().toIso8601String(),
        if (jobId != null) 'job_id': jobId,
        if (notes != null) 'notes': notes,
        'sort_order': sortOrder,
      };

  Map<String, dynamic> toUpdateJson() => {
        'task_type': UnitTurn._enumToDb(taskType),
        'description': description,
        'assigned_to': assignedTo,
        'vendor_id': vendorId,
        'estimated_cost': estimatedCost,
        'actual_cost': actualCost,
        'status': UnitTurn._enumToDb(status),
        'completed_at': completedAt?.toUtc().toIso8601String(),
        'job_id': jobId,
        'notes': notes,
        'sort_order': sortOrder,
      };

  factory UnitTurnTask.fromJson(Map<String, dynamic> json) {
    return UnitTurnTask(
      id: json['id'] as String? ?? '',
      unitTurnId:
          (json['unit_turn_id'] ?? json['unitTurnId']) as String? ?? '',
      taskType: UnitTurn._parseEnum(
        (json['task_type'] ?? json['taskType']) as String?,
        TurnTaskType.values,
        TurnTaskType.general,
      ),
      description: json['description'] as String?,
      assignedTo:
          (json['assigned_to'] ?? json['assignedTo']) as String?,
      vendorId: (json['vendor_id'] ?? json['vendorId']) as String?,
      estimatedCost:
          (json['estimated_cost'] ?? json['estimatedCost'] as num?)
              ?.toDouble(),
      actualCost:
          (json['actual_cost'] ?? json['actualCost'] as num?)?.toDouble(),
      status: UnitTurn._parseEnum(
        json['status'] as String?,
        TurnTaskStatus.values,
        TurnTaskStatus.pending,
      ),
      completedAt: UnitTurn._parseDate(
          json['completed_at'] ?? json['completedAt']),
      jobId: (json['job_id'] ?? json['jobId']) as String?,
      notes: json['notes'] as String?,
      sortOrder:
          (json['sort_order'] ?? json['sortOrder'] as num?)?.toInt() ?? 0,
      createdAt:
          UnitTurn._parseDate(json['created_at'] ?? json['createdAt']) ??
              DateTime.now(),
      updatedAt:
          UnitTurn._parseDate(json['updated_at'] ?? json['updatedAt']) ??
              DateTime.now(),
    );
  }

  UnitTurnTask copyWith({
    String? id,
    String? unitTurnId,
    TurnTaskType? taskType,
    String? description,
    String? assignedTo,
    String? vendorId,
    double? estimatedCost,
    double? actualCost,
    TurnTaskStatus? status,
    DateTime? completedAt,
    String? jobId,
    String? notes,
    int? sortOrder,
  }) {
    return UnitTurnTask(
      id: id ?? this.id,
      unitTurnId: unitTurnId ?? this.unitTurnId,
      taskType: taskType ?? this.taskType,
      description: description ?? this.description,
      assignedTo: assignedTo ?? this.assignedTo,
      vendorId: vendorId ?? this.vendorId,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      actualCost: actualCost ?? this.actualCost,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
      jobId: jobId ?? this.jobId,
      notes: notes ?? this.notes,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
