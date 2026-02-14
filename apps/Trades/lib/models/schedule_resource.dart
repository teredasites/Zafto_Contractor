// ZAFTO Schedule Resource Model — Supabase Backend
// Maps to `schedule_resources` table. Labor, equipment, material definitions.
// GC1: Phase GC foundation.

enum ResourceType { labor, equipment, material }

class ScheduleResource {
  final String id;
  final String companyId;
  final String name;
  final ResourceType resourceType;
  final double maxUnits;
  final double costPerHour;
  final double costPerUnit;
  final double overtimeRateMultiplier;
  final String? trade;
  final String? role;
  final String? userId;
  final String? calendarId;
  final String? color;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const ScheduleResource({
    this.id = '',
    this.companyId = '',
    this.name = '',
    this.resourceType = ResourceType.labor,
    this.maxUnits = 1,
    this.costPerHour = 0,
    this.costPerUnit = 0,
    this.overtimeRateMultiplier = 1.5,
    this.trade,
    this.role,
    this.userId,
    this.calendarId,
    this.color,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  bool get isLabor => resourceType == ResourceType.labor;
  bool get isEquipment => resourceType == ResourceType.equipment;
  bool get isMaterial => resourceType == ResourceType.material;

  Map<String, dynamic> toInsertJson() => {
        'company_id': companyId,
        'name': name,
        'resource_type': resourceType.name,
        'max_units': maxUnits,
        'cost_per_hour': costPerHour,
        'cost_per_unit': costPerUnit,
        'overtime_rate_multiplier': overtimeRateMultiplier,
        if (trade != null) 'trade': trade,
        if (role != null) 'role': role,
        if (userId != null) 'user_id': userId,
        if (calendarId != null) 'calendar_id': calendarId,
        if (color != null) 'color': color,
      };

  factory ScheduleResource.fromJson(Map<String, dynamic> json) {
    return ScheduleResource(
      id: json['id'] as String? ?? '',
      companyId: json['company_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      resourceType: _parseType(json['resource_type'] as String?),
      maxUnits: (json['max_units'] as num?)?.toDouble() ?? 1,
      costPerHour: (json['cost_per_hour'] as num?)?.toDouble() ?? 0,
      costPerUnit: (json['cost_per_unit'] as num?)?.toDouble() ?? 0,
      overtimeRateMultiplier:
          (json['overtime_rate_multiplier'] as num?)?.toDouble() ?? 1.5,
      trade: json['trade'] as String?,
      role: json['role'] as String?,
      userId: json['user_id'] as String?,
      calendarId: json['calendar_id'] as String?,
      color: json['color'] as String?,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
      deletedAt: _parseDateNullable(json['deleted_at']),
    );
  }

  ScheduleResource copyWith({
    String? id, String? companyId, String? name, ResourceType? resourceType,
    double? maxUnits, double? costPerHour, double? costPerUnit,
    double? overtimeRateMultiplier, String? trade, String? role,
    String? userId, String? calendarId, String? color,
    DateTime? createdAt, DateTime? updatedAt, DateTime? deletedAt,
  }) {
    return ScheduleResource(
      id: id ?? this.id, companyId: companyId ?? this.companyId,
      name: name ?? this.name, resourceType: resourceType ?? this.resourceType,
      maxUnits: maxUnits ?? this.maxUnits,
      costPerHour: costPerHour ?? this.costPerHour,
      costPerUnit: costPerUnit ?? this.costPerUnit,
      overtimeRateMultiplier: overtimeRateMultiplier ?? this.overtimeRateMultiplier,
      trade: trade ?? this.trade, role: role ?? this.role,
      userId: userId ?? this.userId, calendarId: calendarId ?? this.calendarId,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  static ResourceType _parseType(String? value) {
    if (value == null) return ResourceType.labor;
    return ResourceType.values.firstWhere(
      (r) => r.name == value, orElse: () => ResourceType.labor,
    );
  }

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
