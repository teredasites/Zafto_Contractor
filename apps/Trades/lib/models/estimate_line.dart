// ZAFTO Estimate Line Model — Supabase Backend
// Maps to `xactimate_estimate_lines` table. Each line is a single billable
// item on an insurance estimate (code, qty, price, room, costs).

class EstimateLine {
  final String id;
  final String companyId;
  final String claimId;
  final String? codeId;
  final String category;
  final String itemCode;
  final String description;
  final double quantity;
  final String unit;
  final double unitPrice;
  final double total;
  final double materialCost;
  final double laborCost;
  final double equipmentCost;
  final String? roomName;
  final int lineNumber;
  final String? coverageGroup;
  final bool isSupplement;
  final String? supplementId;
  final double depreciationRate;
  final double? acvAmount;
  final double? rcvAmount;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const EstimateLine({
    this.id = '',
    this.companyId = '',
    this.claimId = '',
    this.codeId,
    this.category = '',
    this.itemCode = '',
    this.description = '',
    this.quantity = 1,
    this.unit = 'EA',
    this.unitPrice = 0,
    this.total = 0,
    this.materialCost = 0,
    this.laborCost = 0,
    this.equipmentCost = 0,
    this.roomName,
    this.lineNumber = 0,
    this.coverageGroup,
    this.isSupplement = false,
    this.supplementId,
    this.depreciationRate = 0,
    this.acvAmount,
    this.rcvAmount,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  // Computed: recalculate total from qty * unitPrice
  double get computedTotal => quantity * unitPrice;

  // Computed: ACV = RCV - depreciation
  double get computedAcv =>
      (rcvAmount ?? total) * (1 - depreciationRate / 100);

  Map<String, dynamic> toInsertJson() => {
        'company_id': companyId,
        'claim_id': claimId,
        if (codeId != null) 'code_id': codeId,
        'category': category,
        'item_code': itemCode,
        'description': description,
        'quantity': quantity,
        'unit': unit,
        'unit_price': unitPrice,
        'total': computedTotal,
        'material_cost': materialCost,
        'labor_cost': laborCost,
        'equipment_cost': equipmentCost,
        if (roomName != null) 'room_name': roomName,
        'line_number': lineNumber,
        if (coverageGroup != null) 'coverage_group': coverageGroup,
        'is_supplement': isSupplement,
        if (supplementId != null) 'supplement_id': supplementId,
        'depreciation_rate': depreciationRate,
        if (acvAmount != null) 'acv_amount': acvAmount,
        if (rcvAmount != null) 'rcv_amount': rcvAmount,
        if (notes != null) 'notes': notes,
      };

  Map<String, dynamic> toUpdateJson() => {
        if (codeId != null) 'code_id': codeId,
        'category': category,
        'item_code': itemCode,
        'description': description,
        'quantity': quantity,
        'unit': unit,
        'unit_price': unitPrice,
        'total': computedTotal,
        'material_cost': materialCost,
        'labor_cost': laborCost,
        'equipment_cost': equipmentCost,
        'room_name': roomName,
        'line_number': lineNumber,
        'coverage_group': coverageGroup,
        'is_supplement': isSupplement,
        'supplement_id': supplementId,
        'depreciation_rate': depreciationRate,
        'acv_amount': acvAmount,
        'rcv_amount': rcvAmount,
        'notes': notes,
      };

  factory EstimateLine.fromJson(Map<String, dynamic> json) {
    return EstimateLine(
      id: json['id'] as String? ?? '',
      companyId: json['company_id'] as String? ?? '',
      claimId: json['claim_id'] as String? ?? '',
      codeId: json['code_id'] as String?,
      category: json['category'] as String? ?? '',
      itemCode: json['item_code'] as String? ?? '',
      description: json['description'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1,
      unit: json['unit'] as String? ?? 'EA',
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0,
      materialCost: (json['material_cost'] as num?)?.toDouble() ?? 0,
      laborCost: (json['labor_cost'] as num?)?.toDouble() ?? 0,
      equipmentCost: (json['equipment_cost'] as num?)?.toDouble() ?? 0,
      roomName: json['room_name'] as String?,
      lineNumber: json['line_number'] as int? ?? 0,
      coverageGroup: json['coverage_group'] as String?,
      isSupplement: json['is_supplement'] as bool? ?? false,
      supplementId: json['supplement_id'] as String?,
      depreciationRate: (json['depreciation_rate'] as num?)?.toDouble() ?? 0,
      acvAmount: (json['acv_amount'] as num?)?.toDouble(),
      rcvAmount: (json['rcv_amount'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  EstimateLine copyWith({
    String? id,
    String? companyId,
    String? claimId,
    String? codeId,
    String? category,
    String? itemCode,
    String? description,
    double? quantity,
    String? unit,
    double? unitPrice,
    double? total,
    double? materialCost,
    double? laborCost,
    double? equipmentCost,
    String? roomName,
    int? lineNumber,
    String? coverageGroup,
    bool? isSupplement,
    String? supplementId,
    double? depreciationRate,
    double? acvAmount,
    double? rcvAmount,
    String? notes,
  }) {
    return EstimateLine(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      claimId: claimId ?? this.claimId,
      codeId: codeId ?? this.codeId,
      category: category ?? this.category,
      itemCode: itemCode ?? this.itemCode,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      unitPrice: unitPrice ?? this.unitPrice,
      total: total ?? this.total,
      materialCost: materialCost ?? this.materialCost,
      laborCost: laborCost ?? this.laborCost,
      equipmentCost: equipmentCost ?? this.equipmentCost,
      roomName: roomName ?? this.roomName,
      lineNumber: lineNumber ?? this.lineNumber,
      coverageGroup: coverageGroup ?? this.coverageGroup,
      isSupplement: isSupplement ?? this.isSupplement,
      supplementId: supplementId ?? this.supplementId,
      depreciationRate: depreciationRate ?? this.depreciationRate,
      acvAmount: acvAmount ?? this.acvAmount,
      rcvAmount: rcvAmount ?? this.rcvAmount,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }
}
