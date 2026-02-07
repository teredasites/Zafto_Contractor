// Property Management Models — Property Assets
// Maps to `property_assets` and `asset_service_records` tables in Supabase PostgreSQL.
// Tracks physical assets (HVAC, appliances, etc.) and their service history.

enum AssetType {
  hvac,
  waterHeater,
  appliance,
  roof,
  plumbing,
  electrical,
  flooring,
  window,
  door,
  exterior,
  landscaping,
  security,
  other,
}

enum AssetCondition {
  excellent,
  good,
  fair,
  poor,
  needsReplacement,
}

enum AssetStatus {
  active,
  retired,
  replaced,
}

enum ServiceType {
  routine,
  repair,
  replacement,
  inspection,
  emergency,
}

class PropertyAsset {
  final String id;
  final String companyId;
  final String propertyId;
  final String? unitId;
  final AssetType assetType;
  final String? brand;
  final String? model;
  final String? serialNumber;
  final DateTime? installDate;
  final DateTime? warrantyExpires;
  final int? expectedLifespanYears;
  final double? replacementCost;
  final DateTime? lastServiceDate;
  final DateTime? nextServiceDate;
  final AssetCondition condition;
  final String? notes;
  final AssetStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PropertyAsset({
    this.id = '',
    this.companyId = '',
    this.propertyId = '',
    this.unitId,
    this.assetType = AssetType.other,
    this.brand,
    this.model,
    this.serialNumber,
    this.installDate,
    this.warrantyExpires,
    this.expectedLifespanYears,
    this.replacementCost,
    this.lastServiceDate,
    this.nextServiceDate,
    this.condition = AssetCondition.good,
    this.notes,
    this.status = AssetStatus.active,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get needsService =>
      nextServiceDate != null && nextServiceDate!.isBefore(DateTime.now());

  bool get warrantyActive =>
      warrantyExpires != null && warrantyExpires!.isAfter(DateTime.now());

  Map<String, dynamic> toInsertJson() => {
        'company_id': companyId,
        'property_id': propertyId,
        if (unitId != null) 'unit_id': unitId,
        'asset_type': _enumToDb(assetType),
        if (brand != null) 'brand': brand,
        if (model != null) 'model': model,
        if (serialNumber != null) 'serial_number': serialNumber,
        if (installDate != null)
          'install_date': installDate!.toUtc().toIso8601String(),
        if (warrantyExpires != null)
          'warranty_expires': warrantyExpires!.toUtc().toIso8601String(),
        if (expectedLifespanYears != null)
          'expected_lifespan_years': expectedLifespanYears,
        if (replacementCost != null) 'replacement_cost': replacementCost,
        if (lastServiceDate != null)
          'last_service_date': lastServiceDate!.toUtc().toIso8601String(),
        if (nextServiceDate != null)
          'next_service_date': nextServiceDate!.toUtc().toIso8601String(),
        'condition': _enumToDb(condition),
        if (notes != null) 'notes': notes,
        'status': _enumToDb(status),
      };

  Map<String, dynamic> toUpdateJson() => {
        'unit_id': unitId,
        'asset_type': _enumToDb(assetType),
        'brand': brand,
        'model': model,
        'serial_number': serialNumber,
        'install_date': installDate?.toUtc().toIso8601String(),
        'warranty_expires': warrantyExpires?.toUtc().toIso8601String(),
        'expected_lifespan_years': expectedLifespanYears,
        'replacement_cost': replacementCost,
        'last_service_date': lastServiceDate?.toUtc().toIso8601String(),
        'next_service_date': nextServiceDate?.toUtc().toIso8601String(),
        'condition': _enumToDb(condition),
        'notes': notes,
        'status': _enumToDb(status),
      };

  factory PropertyAsset.fromJson(Map<String, dynamic> json) {
    return PropertyAsset(
      id: json['id'] as String? ?? '',
      companyId:
          (json['company_id'] ?? json['companyId']) as String? ?? '',
      propertyId:
          (json['property_id'] ?? json['propertyId']) as String? ?? '',
      unitId: (json['unit_id'] ?? json['unitId']) as String?,
      assetType: _parseEnum(
        (json['asset_type'] ?? json['assetType']) as String?,
        AssetType.values,
        AssetType.other,
      ),
      brand: json['brand'] as String?,
      model: json['model'] as String?,
      serialNumber:
          (json['serial_number'] ?? json['serialNumber']) as String?,
      installDate: _parseDate(
          json['install_date'] ?? json['installDate']),
      warrantyExpires: _parseDate(
          json['warranty_expires'] ?? json['warrantyExpires']),
      expectedLifespanYears:
          (json['expected_lifespan_years'] ??
                  json['expectedLifespanYears'] as num?)
              ?.toInt(),
      replacementCost:
          (json['replacement_cost'] ?? json['replacementCost'] as num?)
              ?.toDouble(),
      lastServiceDate: _parseDate(
          json['last_service_date'] ?? json['lastServiceDate']),
      nextServiceDate: _parseDate(
          json['next_service_date'] ?? json['nextServiceDate']),
      condition: _parseEnum(
        (json['condition'] as String?),
        AssetCondition.values,
        AssetCondition.good,
      ),
      notes: json['notes'] as String?,
      status: _parseEnum(
        json['status'] as String?,
        AssetStatus.values,
        AssetStatus.active,
      ),
      createdAt:
          _parseDate(json['created_at'] ?? json['createdAt']) ??
              DateTime.now(),
      updatedAt:
          _parseDate(json['updated_at'] ?? json['updatedAt']) ??
              DateTime.now(),
    );
  }

  PropertyAsset copyWith({
    String? id,
    String? companyId,
    String? propertyId,
    String? unitId,
    AssetType? assetType,
    String? brand,
    String? model,
    String? serialNumber,
    DateTime? installDate,
    DateTime? warrantyExpires,
    int? expectedLifespanYears,
    double? replacementCost,
    DateTime? lastServiceDate,
    DateTime? nextServiceDate,
    AssetCondition? condition,
    String? notes,
    AssetStatus? status,
  }) {
    return PropertyAsset(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      propertyId: propertyId ?? this.propertyId,
      unitId: unitId ?? this.unitId,
      assetType: assetType ?? this.assetType,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      serialNumber: serialNumber ?? this.serialNumber,
      installDate: installDate ?? this.installDate,
      warrantyExpires: warrantyExpires ?? this.warrantyExpires,
      expectedLifespanYears:
          expectedLifespanYears ?? this.expectedLifespanYears,
      replacementCost: replacementCost ?? this.replacementCost,
      lastServiceDate: lastServiceDate ?? this.lastServiceDate,
      nextServiceDate: nextServiceDate ?? this.nextServiceDate,
      condition: condition ?? this.condition,
      notes: notes ?? this.notes,
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

class AssetServiceRecord {
  final String id;
  final String assetId;
  final ServiceType serviceType;
  final DateTime? serviceDate;
  final String? performedBy;
  final String? vendorId;
  final double? cost;
  final String? description;
  final List<String> partsUsed;
  final DateTime? nextServiceDate;
  final String? notes;
  final DateTime createdAt;

  const AssetServiceRecord({
    this.id = '',
    this.assetId = '',
    this.serviceType = ServiceType.routine,
    this.serviceDate,
    this.performedBy,
    this.vendorId,
    this.cost,
    this.description,
    this.partsUsed = const [],
    this.nextServiceDate,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toInsertJson() => {
        'asset_id': assetId,
        'service_type': PropertyAsset._enumToDb(serviceType),
        if (serviceDate != null)
          'service_date': serviceDate!.toUtc().toIso8601String(),
        if (performedBy != null) 'performed_by': performedBy,
        if (vendorId != null) 'vendor_id': vendorId,
        if (cost != null) 'cost': cost,
        if (description != null) 'description': description,
        'parts_used': partsUsed,
        if (nextServiceDate != null)
          'next_service_date': nextServiceDate!.toUtc().toIso8601String(),
        if (notes != null) 'notes': notes,
      };

  // Service records are append-only (history) — no toUpdateJson.

  factory AssetServiceRecord.fromJson(Map<String, dynamic> json) {
    return AssetServiceRecord(
      id: json['id'] as String? ?? '',
      assetId:
          (json['asset_id'] ?? json['assetId']) as String? ?? '',
      serviceType: PropertyAsset._parseEnum(
        (json['service_type'] ?? json['serviceType']) as String?,
        ServiceType.values,
        ServiceType.routine,
      ),
      serviceDate: PropertyAsset._parseDate(
          json['service_date'] ?? json['serviceDate']),
      performedBy:
          (json['performed_by'] ?? json['performedBy']) as String?,
      vendorId: (json['vendor_id'] ?? json['vendorId']) as String?,
      cost: (json['cost'] as num?)?.toDouble(),
      description: json['description'] as String?,
      partsUsed: (json['parts_used'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      nextServiceDate: PropertyAsset._parseDate(
          json['next_service_date'] ?? json['nextServiceDate']),
      notes: json['notes'] as String?,
      createdAt:
          PropertyAsset._parseDate(
              json['created_at'] ?? json['createdAt']) ??
          DateTime.now(),
    );
  }

  AssetServiceRecord copyWith({
    String? id,
    String? assetId,
    ServiceType? serviceType,
    DateTime? serviceDate,
    String? performedBy,
    String? vendorId,
    double? cost,
    String? description,
    List<String>? partsUsed,
    DateTime? nextServiceDate,
    String? notes,
  }) {
    return AssetServiceRecord(
      id: id ?? this.id,
      assetId: assetId ?? this.assetId,
      serviceType: serviceType ?? this.serviceType,
      serviceDate: serviceDate ?? this.serviceDate,
      performedBy: performedBy ?? this.performedBy,
      vendorId: vendorId ?? this.vendorId,
      cost: cost ?? this.cost,
      description: description ?? this.description,
      partsUsed: partsUsed ?? this.partsUsed,
      nextServiceDate: nextServiceDate ?? this.nextServiceDate,
      notes: notes ?? this.notes,
      createdAt: createdAt,
    );
  }
}
