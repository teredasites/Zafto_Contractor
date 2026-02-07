// Property Management Models — Inspections
// Maps to `pm_inspections` and `pm_inspection_items` tables in Supabase PostgreSQL.
// Handles move-in, move-out, routine, and safety inspections.

enum InspectionType {
  moveIn,
  moveOut,
  routine,
  annual,
  maintenance,
  safety,
}

enum InspectionStatus {
  scheduled,
  inProgress,
  completed,
  cancelled,
}

enum ItemCondition {
  excellent,
  good,
  fair,
  poor,
  damaged,
  missing,
}

class PmInspection {
  final String id;
  final String companyId;
  final String propertyId;
  final String? unitId;
  final String? inspectorId;
  final InspectionType inspectionType;
  final DateTime? scheduledDate;
  final DateTime? completedDate;
  final ItemCondition? overallCondition;
  final int? score;
  final String? notes;
  final List<String> photos;
  final InspectionStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PmInspection({
    this.id = '',
    this.companyId = '',
    this.propertyId = '',
    this.unitId,
    this.inspectorId,
    this.inspectionType = InspectionType.routine,
    this.scheduledDate,
    this.completedDate,
    this.overallCondition,
    this.score,
    this.notes,
    this.photos = const [],
    this.status = InspectionStatus.scheduled,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toInsertJson() => {
        'company_id': companyId,
        'property_id': propertyId,
        if (unitId != null) 'unit_id': unitId,
        if (inspectorId != null) 'inspector_id': inspectorId,
        'inspection_type': _enumToDb(inspectionType),
        if (scheduledDate != null)
          'scheduled_date': scheduledDate!.toUtc().toIso8601String(),
        if (completedDate != null)
          'completed_date': completedDate!.toUtc().toIso8601String(),
        if (overallCondition != null)
          'overall_condition': _enumToDb(overallCondition!),
        if (score != null) 'score': score,
        if (notes != null) 'notes': notes,
        'photos': photos,
        'status': _enumToDb(status),
      };

  Map<String, dynamic> toUpdateJson() => {
        'unit_id': unitId,
        'inspector_id': inspectorId,
        'inspection_type': _enumToDb(inspectionType),
        'scheduled_date': scheduledDate?.toUtc().toIso8601String(),
        'completed_date': completedDate?.toUtc().toIso8601String(),
        'overall_condition':
            overallCondition != null ? _enumToDb(overallCondition!) : null,
        'score': score,
        'notes': notes,
        'photos': photos,
        'status': _enumToDb(status),
      };

  factory PmInspection.fromJson(Map<String, dynamic> json) {
    return PmInspection(
      id: json['id'] as String? ?? '',
      companyId:
          (json['company_id'] ?? json['companyId']) as String? ?? '',
      propertyId:
          (json['property_id'] ?? json['propertyId']) as String? ?? '',
      unitId: (json['unit_id'] ?? json['unitId']) as String?,
      inspectorId:
          (json['inspector_id'] ?? json['inspectorId']) as String?,
      inspectionType: _parseEnum(
        (json['inspection_type'] ?? json['inspectionType']) as String?,
        InspectionType.values,
        InspectionType.routine,
      ),
      scheduledDate: _parseDate(
          json['scheduled_date'] ?? json['scheduledDate']),
      completedDate: _parseDate(
          json['completed_date'] ?? json['completedDate']),
      overallCondition: json['overall_condition'] != null ||
              json['overallCondition'] != null
          ? _parseEnum(
              (json['overall_condition'] ?? json['overallCondition'])
                  as String?,
              ItemCondition.values,
              ItemCondition.good,
            )
          : null,
      score: (json['score'] as num?)?.toInt(),
      notes: json['notes'] as String?,
      photos: (json['photos'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      status: _parseEnum(
        json['status'] as String?,
        InspectionStatus.values,
        InspectionStatus.scheduled,
      ),
      createdAt:
          _parseDate(json['created_at'] ?? json['createdAt']) ??
              DateTime.now(),
      updatedAt:
          _parseDate(json['updated_at'] ?? json['updatedAt']) ??
              DateTime.now(),
    );
  }

  PmInspection copyWith({
    String? id,
    String? companyId,
    String? propertyId,
    String? unitId,
    String? inspectorId,
    InspectionType? inspectionType,
    DateTime? scheduledDate,
    DateTime? completedDate,
    ItemCondition? overallCondition,
    int? score,
    String? notes,
    List<String>? photos,
    InspectionStatus? status,
  }) {
    return PmInspection(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      propertyId: propertyId ?? this.propertyId,
      unitId: unitId ?? this.unitId,
      inspectorId: inspectorId ?? this.inspectorId,
      inspectionType: inspectionType ?? this.inspectionType,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      completedDate: completedDate ?? this.completedDate,
      overallCondition: overallCondition ?? this.overallCondition,
      score: score ?? this.score,
      notes: notes ?? this.notes,
      photos: photos ?? this.photos,
      status: status ?? this.status,
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

class PmInspectionItem {
  final String id;
  final String inspectionId;
  final String area;
  final String itemName;
  final ItemCondition condition;
  final String? notes;
  final List<String> photos;
  final int sortOrder;
  final DateTime createdAt;

  const PmInspectionItem({
    this.id = '',
    this.inspectionId = '',
    required this.area,
    required this.itemName,
    this.condition = ItemCondition.good,
    this.notes,
    this.photos = const [],
    this.sortOrder = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toInsertJson() => {
        'inspection_id': inspectionId,
        'area': area,
        'item_name': itemName,
        'condition': PmInspection._enumToDb(condition),
        if (notes != null) 'notes': notes,
        'photos': photos,
        'sort_order': sortOrder,
      };

  Map<String, dynamic> toUpdateJson() => {
        'area': area,
        'item_name': itemName,
        'condition': PmInspection._enumToDb(condition),
        'notes': notes,
        'photos': photos,
        'sort_order': sortOrder,
      };

  factory PmInspectionItem.fromJson(Map<String, dynamic> json) {
    return PmInspectionItem(
      id: json['id'] as String? ?? '',
      inspectionId:
          (json['inspection_id'] ?? json['inspectionId']) as String? ?? '',
      area: (json['area'] as String?) ?? '',
      itemName:
          (json['item_name'] ?? json['itemName']) as String? ?? '',
      condition: PmInspection._parseEnum(
        json['condition'] as String?,
        ItemCondition.values,
        ItemCondition.good,
      ),
      notes: json['notes'] as String?,
      photos: (json['photos'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      sortOrder:
          (json['sort_order'] ?? json['sortOrder'] as num?)?.toInt() ?? 0,
      createdAt:
          PmInspection._parseDate(
              json['created_at'] ?? json['createdAt']) ??
          DateTime.now(),
    );
  }

  PmInspectionItem copyWith({
    String? id,
    String? inspectionId,
    String? area,
    String? itemName,
    ItemCondition? condition,
    String? notes,
    List<String>? photos,
    int? sortOrder,
  }) {
    return PmInspectionItem(
      id: id ?? this.id,
      inspectionId: inspectionId ?? this.inspectionId,
      area: area ?? this.area,
      itemName: itemName ?? this.itemName,
      condition: condition ?? this.condition,
      notes: notes ?? this.notes,
      photos: photos ?? this.photos,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt,
    );
  }
}
