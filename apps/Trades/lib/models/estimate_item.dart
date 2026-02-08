// ZAFTO Estimate Item Model — Code Database Entry
// Created: Sprint D8c (Session 86)
//
// Matches public.estimate_items table.
// ZAFTO's own code database — independent from Xactimate.
// Dual access: ZAFTO-seeded items (company_id IS NULL) are shared,
// company-specific items scoped by RLS.

class EstimateItem {
  final String id;
  final String categoryId;
  final String? companyId;
  final String zaftoCode;
  final String? industryCode;
  final String? industrySelector;
  final String description;
  final String unitCode;
  final List<String> actionTypes;
  final String trade;
  final String? subtrade;
  final List<String>? tags;
  final bool isCommon;
  final String source;
  final int? lifeExpectancyYears;
  final int? depreciationMaxPct;
  final DateTime createdAt;
  final DateTime updatedAt;

  const EstimateItem({
    this.id = '',
    required this.categoryId,
    this.companyId,
    required this.zaftoCode,
    this.industryCode,
    this.industrySelector,
    required this.description,
    this.unitCode = 'EA',
    this.actionTypes = const ['add'],
    required this.trade,
    this.subtrade,
    this.tags,
    this.isCommon = false,
    this.source = 'zafto',
    this.lifeExpectancyYears,
    this.depreciationMaxPct,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EstimateItem.fromJson(Map<String, dynamic> json) => EstimateItem(
        id: json['id'] as String? ?? '',
        categoryId: json['category_id'] as String? ?? '',
        companyId: json['company_id'] as String?,
        zaftoCode: json['zafto_code'] as String? ?? '',
        industryCode: json['industry_code'] as String?,
        industrySelector: json['industry_selector'] as String?,
        description: json['description'] as String? ?? '',
        unitCode: json['unit_code'] as String? ?? 'EA',
        actionTypes: (json['action_types'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const ['add'],
        trade: json['trade'] as String? ?? '',
        subtrade: json['subtrade'] as String?,
        tags: (json['tags'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList(),
        isCommon: json['is_common'] as bool? ?? false,
        source: json['source'] as String? ?? 'zafto',
        lifeExpectancyYears: json['life_expectancy_years'] as int?,
        depreciationMaxPct: json['depreciation_max_pct'] as int?,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.now(),
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : DateTime.now(),
      );

  Map<String, dynamic> toInsertJson() => {
        'category_id': categoryId,
        'company_id': companyId,
        'zafto_code': zaftoCode,
        'industry_code': industryCode,
        'industry_selector': industrySelector,
        'description': description,
        'unit_code': unitCode,
        'action_types': actionTypes,
        'trade': trade,
        'subtrade': subtrade,
        'tags': tags,
        'is_common': isCommon,
        'source': source,
        'life_expectancy_years': lifeExpectancyYears,
        'depreciation_max_pct': depreciationMaxPct,
      };

  bool get isZaftoSeeded => companyId == null;
  bool get isCompanyItem => companyId != null;

  String get fullCode {
    if (industryCode != null && industrySelector != null) {
      return '$industryCode $industrySelector';
    }
    return zaftoCode;
  }
}

// ============================================================
// ESTIMATE CATEGORY (reference data)
// ============================================================

class EstimateCategory {
  final String id;
  final String code;
  final String? industryCode;
  final String name;
  final int laborPct;
  final int materialPct;
  final int equipmentPct;
  final int sortOrder;

  const EstimateCategory({
    this.id = '',
    required this.code,
    this.industryCode,
    required this.name,
    this.laborPct = 50,
    this.materialPct = 40,
    this.equipmentPct = 10,
    this.sortOrder = 0,
  });

  factory EstimateCategory.fromJson(Map<String, dynamic> json) =>
      EstimateCategory(
        id: json['id'] as String? ?? '',
        code: json['code'] as String? ?? '',
        industryCode: json['industry_code'] as String?,
        name: json['name'] as String? ?? '',
        laborPct: json['labor_pct'] as int? ?? 50,
        materialPct: json['material_pct'] as int? ?? 40,
        equipmentPct: json['equipment_pct'] as int? ?? 10,
        sortOrder: json['sort_order'] as int? ?? 0,
      );
}

// ============================================================
// ESTIMATE UNIT (reference data)
// ============================================================

class EstimateUnit {
  final String id;
  final String code;
  final String name;
  final String abbreviation;

  const EstimateUnit({
    this.id = '',
    required this.code,
    required this.name,
    required this.abbreviation,
  });

  factory EstimateUnit.fromJson(Map<String, dynamic> json) => EstimateUnit(
        id: json['id'] as String? ?? '',
        code: json['code'] as String? ?? '',
        name: json['name'] as String? ?? '',
        abbreviation: json['abbreviation'] as String? ?? '',
      );
}
