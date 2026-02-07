// ZAFTO Xactimate Code Model — Supabase Backend
// Maps to `xactimate_codes` table. Reference data for insurance estimate
// line codes. Read-only from the mobile app (populated by admin/AI pipeline).

class XactimateCode {
  final String id;
  final String categoryCode;
  final String categoryName;
  final String? selectorCode;
  final String fullCode;
  final String description;
  final String unit;
  final String? coverageGroup;
  final bool hasMaterial;
  final bool hasLabor;
  final bool hasEquipment;
  final bool deprecated;

  const XactimateCode({
    this.id = '',
    this.categoryCode = '',
    this.categoryName = '',
    this.selectorCode,
    this.fullCode = '',
    this.description = '',
    this.unit = 'EA',
    this.coverageGroup,
    this.hasMaterial = false,
    this.hasLabor = false,
    this.hasEquipment = false,
    this.deprecated = false,
  });

  // Display label: "WTR DRY1 — Extraction, standing water"
  String get displayLabel => '$fullCode — $description';

  // Short display for list tiles
  String get shortLabel =>
      description.length > 60 ? '${description.substring(0, 57)}...' : description;

  // Cost components summary
  String get costComponents {
    final parts = <String>[];
    if (hasMaterial) parts.add('Mat');
    if (hasLabor) parts.add('Lab');
    if (hasEquipment) parts.add('Eqp');
    return parts.isEmpty ? 'N/A' : parts.join(' + ');
  }

  factory XactimateCode.fromJson(Map<String, dynamic> json) {
    return XactimateCode(
      id: json['id'] as String? ?? '',
      categoryCode: json['category_code'] as String? ?? '',
      categoryName: json['category_name'] as String? ?? '',
      selectorCode: json['selector_code'] as String?,
      fullCode: json['full_code'] as String? ?? '',
      description: json['description'] as String? ?? '',
      unit: json['unit'] as String? ?? 'EA',
      coverageGroup: json['coverage_group'] as String?,
      hasMaterial: json['has_material'] as bool? ?? false,
      hasLabor: json['has_labor'] as bool? ?? false,
      hasEquipment: json['has_equipment'] as bool? ?? false,
      deprecated: json['deprecated'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'category_code': categoryCode,
        'category_name': categoryName,
        'selector_code': selectorCode,
        'full_code': fullCode,
        'description': description,
        'unit': unit,
        'coverage_group': coverageGroup,
        'has_material': hasMaterial,
        'has_labor': hasLabor,
        'has_equipment': hasEquipment,
        'deprecated': deprecated,
      };
}

// Pricing data from pricing_entries table (joined to codes)
class PricingEntry {
  final String id;
  final String codeId;
  final String? regionCode;
  final double materialCost;
  final double laborCost;
  final double equipmentCost;
  final double totalCost;
  final double? confidence;
  final int? sourceCount;

  const PricingEntry({
    this.id = '',
    this.codeId = '',
    this.regionCode,
    this.materialCost = 0,
    this.laborCost = 0,
    this.equipmentCost = 0,
    this.totalCost = 0,
    this.confidence,
    this.sourceCount,
  });

  factory PricingEntry.fromJson(Map<String, dynamic> json) {
    return PricingEntry(
      id: json['id'] as String? ?? '',
      codeId: json['code_id'] as String? ?? '',
      regionCode: json['region_code'] as String?,
      materialCost: (json['material_cost'] as num?)?.toDouble() ?? 0,
      laborCost: (json['labor_cost'] as num?)?.toDouble() ?? 0,
      equipmentCost: (json['equipment_cost'] as num?)?.toDouble() ?? 0,
      totalCost: (json['total_cost'] as num?)?.toDouble() ?? 0,
      confidence: (json['confidence'] as num?)?.toDouble(),
      sourceCount: json['source_count'] as int?,
    );
  }
}

// Template from estimate_templates table
class EstimateTemplate {
  final String id;
  final String companyId;
  final String name;
  final String? description;
  final String? tradeType;
  final String? lossType;
  final List<Map<String, dynamic>> lineItems;
  final bool isSystem;
  final int usageCount;

  const EstimateTemplate({
    this.id = '',
    this.companyId = '',
    this.name = '',
    this.description,
    this.tradeType,
    this.lossType,
    this.lineItems = const [],
    this.isSystem = false,
    this.usageCount = 0,
  });

  factory EstimateTemplate.fromJson(Map<String, dynamic> json) {
    return EstimateTemplate(
      id: json['id'] as String? ?? '',
      companyId: json['company_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      tradeType: json['trade_type'] as String?,
      lossType: json['loss_type'] as String?,
      lineItems: (json['line_items'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      isSystem: json['is_system'] as bool? ?? false,
      usageCount: json['usage_count'] as int? ?? 0,
    );
  }

  // Number of line items in this template
  int get lineCount => lineItems.length;

  // Display subtitle
  String get subtitle {
    final parts = <String>[];
    if (tradeType != null) parts.add(tradeType!);
    if (lossType != null) parts.add(lossType!);
    parts.add('$lineCount items');
    return parts.join(' · ');
  }
}
