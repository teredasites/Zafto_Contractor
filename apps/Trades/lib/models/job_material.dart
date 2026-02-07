// ZAFTO Job Material Model — Supabase Backend
// Maps to `job_materials` table in Supabase PostgreSQL.
// Tracks materials, equipment, tools, consumables, and rentals used on jobs.

enum MaterialCategory {
  material,
  equipment,
  tool,
  consumable,
  rental;

  String get dbValue => name;

  String get label {
    switch (this) {
      case MaterialCategory.material:
        return 'Material';
      case MaterialCategory.equipment:
        return 'Equipment';
      case MaterialCategory.tool:
        return 'Tool';
      case MaterialCategory.consumable:
        return 'Consumable';
      case MaterialCategory.rental:
        return 'Rental';
    }
  }

  static MaterialCategory fromString(String? value) {
    if (value == null) return MaterialCategory.material;
    return MaterialCategory.values.firstWhere(
      (c) => c.name == value,
      orElse: () => MaterialCategory.material,
    );
  }
}

class JobMaterial {
  final String id;
  final String companyId;
  final String jobId;
  final String addedByUserId;
  final String name;
  final String? description;
  final MaterialCategory category;
  final double quantity;
  final String unit;
  final double? unitCost;
  final double? totalCost;
  final String? vendor;
  final String? receiptId;
  final bool isBillable;
  final DateTime? installedAt;
  final String? serialNumber;
  final String? warrantyInfo;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  JobMaterial({
    this.id = '',
    this.companyId = '',
    this.jobId = '',
    this.addedByUserId = '',
    required this.name,
    this.description,
    this.category = MaterialCategory.material,
    this.quantity = 1,
    this.unit = 'each',
    this.unitCost,
    this.totalCost,
    this.vendor,
    this.receiptId,
    this.isBillable = true,
    this.installedAt,
    this.serialNumber,
    this.warrantyInfo,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.deletedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Computed total: quantity * unitCost (if both available).
  double get computedTotal => (unitCost != null) ? quantity * unitCost! : (totalCost ?? 0);

  // Supabase INSERT — omit id, created_at, updated_at (DB defaults).
  Map<String, dynamic> toInsertJson() => {
        'company_id': companyId,
        'job_id': jobId,
        'added_by_user_id': addedByUserId,
        'name': name,
        if (description != null) 'description': description,
        'category': category.dbValue,
        'quantity': quantity,
        'unit': unit,
        if (unitCost != null) 'unit_cost': unitCost,
        'total_cost': computedTotal,
        if (vendor != null) 'vendor': vendor,
        if (receiptId != null) 'receipt_id': receiptId,
        'is_billable': isBillable,
        if (installedAt != null)
          'installed_at': installedAt!.toUtc().toIso8601String(),
        if (serialNumber != null) 'serial_number': serialNumber,
        if (warrantyInfo != null) 'warranty_info': warrantyInfo,
        if (notes != null) 'notes': notes,
      };

  // Supabase UPDATE — only changed fields.
  Map<String, dynamic> toUpdateJson() => {
        'name': name,
        'description': description,
        'category': category.dbValue,
        'quantity': quantity,
        'unit': unit,
        'unit_cost': unitCost,
        'total_cost': computedTotal,
        'vendor': vendor,
        'is_billable': isBillable,
        'serial_number': serialNumber,
        'warranty_info': warrantyInfo,
        'notes': notes,
      };

  factory JobMaterial.fromJson(Map<String, dynamic> json) {
    return JobMaterial(
      id: json['id'] as String? ?? '',
      companyId: json['company_id'] as String? ?? '',
      jobId: json['job_id'] as String? ?? '',
      addedByUserId: json['added_by_user_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      category: MaterialCategory.fromString(json['category'] as String?),
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1,
      unit: json['unit'] as String? ?? 'each',
      unitCost: (json['unit_cost'] as num?)?.toDouble(),
      totalCost: (json['total_cost'] as num?)?.toDouble(),
      vendor: json['vendor'] as String?,
      receiptId: json['receipt_id'] as String?,
      isBillable: json['is_billable'] as bool? ?? true,
      installedAt: _parseOptionalDate(json['installed_at']),
      serialNumber: json['serial_number'] as String?,
      warrantyInfo: json['warranty_info'] as String?,
      notes: json['notes'] as String?,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
      deletedAt: _parseOptionalDate(json['deleted_at']),
    );
  }

  JobMaterial copyWith({
    String? id,
    String? companyId,
    String? jobId,
    String? addedByUserId,
    String? name,
    String? description,
    MaterialCategory? category,
    double? quantity,
    String? unit,
    double? unitCost,
    double? totalCost,
    String? vendor,
    String? receiptId,
    bool? isBillable,
    DateTime? installedAt,
    String? serialNumber,
    String? warrantyInfo,
    String? notes,
  }) {
    return JobMaterial(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      jobId: jobId ?? this.jobId,
      addedByUserId: addedByUserId ?? this.addedByUserId,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      unitCost: unitCost ?? this.unitCost,
      totalCost: totalCost ?? this.totalCost,
      vendor: vendor ?? this.vendor,
      receiptId: receiptId ?? this.receiptId,
      isBillable: isBillable ?? this.isBillable,
      installedAt: installedAt ?? this.installedAt,
      serialNumber: serialNumber ?? this.serialNumber,
      warrantyInfo: warrantyInfo ?? this.warrantyInfo,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  static DateTime? _parseOptionalDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
