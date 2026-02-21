// ZAFTO Recon-to-Estimate Pipeline Models
// Created: DEPTH30 — One Address → Complete Bid
//
// Models for:
// ReconEstimateMapping, ReconMaterialRecommendation,
// EstimateBundle, CrossTradeDependency, ReconEstimateResult

import 'package:equatable/equatable.dart';

// ════════════════════════════════════════════════════════════════
// RECON-TO-ESTIMATE MAPPING
// ════════════════════════════════════════════════════════════════

/// Maps trade + measurement_type → estimate line item template
class ReconEstimateMapping extends Equatable {
  final String id;
  final String? companyId;
  final String trade;
  final String measurementType;
  final String lineDescription;
  final String? materialCategory;
  final String defaultMaterialTier;
  final String unitCode;
  final String quantityFormula;
  final double wasteFactorPct;
  final double? roundUpTo;
  final String? laborTaskName;
  final int sortOrder;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ReconEstimateMapping({
    required this.id,
    this.companyId,
    required this.trade,
    required this.measurementType,
    required this.lineDescription,
    this.materialCategory,
    this.defaultMaterialTier = 'standard',
    this.unitCode = 'SF',
    required this.quantityFormula,
    this.wasteFactorPct = 0,
    this.roundUpTo,
    this.laborTaskName,
    this.sortOrder = 0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Whether this is a system default (no company override)
  bool get isSystemDefault => companyId == null;

  /// Evaluate the quantity formula with a measurement value
  double evaluateQuantity(double measurementValue) {
    // Parse simple formulas: 'measurement', 'measurement * 1.10', 'measurement / 100', '1'
    final formula = quantityFormula.trim().toLowerCase();

    if (formula == 'measurement') return measurementValue;

    // Try parsing as a constant number
    final constantValue = double.tryParse(formula);
    if (constantValue != null) return constantValue;

    // Parse "measurement * X" or "measurement / X"
    if (formula.startsWith('measurement')) {
      final rest = formula.substring('measurement'.length).trim();
      if (rest.startsWith('*')) {
        final multiplier = double.tryParse(rest.substring(1).trim()) ?? 1;
        return measurementValue * multiplier;
      }
      if (rest.startsWith('/')) {
        final divisor = double.tryParse(rest.substring(1).trim()) ?? 1;
        if (divisor == 0) return 0;
        return measurementValue / divisor;
      }
    }

    return measurementValue;
  }

  /// Calculate final quantity with waste factor and rounding
  double calculateQuantity(double measurementValue) {
    var qty = evaluateQuantity(measurementValue);

    // Apply waste factor
    if (wasteFactorPct > 0) {
      qty *= (1 + wasteFactorPct / 100);
    }

    // Round up to purchasable units
    if (roundUpTo != null && roundUpTo! > 0) {
      qty = (qty / roundUpTo!).ceil() * roundUpTo!;
    }

    return qty;
  }

  factory ReconEstimateMapping.fromJson(Map<String, dynamic> json) {
    return ReconEstimateMapping(
      id: json['id'] as String,
      companyId: json['company_id'] as String?,
      trade: (json['trade'] as String?) ?? '',
      measurementType: (json['measurement_type'] as String?) ?? '',
      lineDescription: (json['line_description'] as String?) ?? '',
      materialCategory: json['material_category'] as String?,
      defaultMaterialTier: (json['default_material_tier'] as String?) ?? 'standard',
      unitCode: (json['unit_code'] as String?) ?? 'SF',
      quantityFormula: (json['quantity_formula'] as String?) ?? 'measurement',
      wasteFactorPct: (json['waste_factor_pct'] as num?)?.toDouble() ?? 0,
      roundUpTo: (json['round_up_to'] as num?)?.toDouble(),
      laborTaskName: json['labor_task_name'] as String?,
      sortOrder: (json['sort_order'] as int?) ?? 0,
      isActive: json['is_active'] != false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'company_id': companyId,
        'trade': trade,
        'measurement_type': measurementType,
        'line_description': lineDescription,
        'material_category': materialCategory,
        'default_material_tier': defaultMaterialTier,
        'unit_code': unitCode,
        'quantity_formula': quantityFormula,
        'waste_factor_pct': wasteFactorPct,
        'round_up_to': roundUpTo,
        'labor_task_name': laborTaskName,
        'sort_order': sortOrder,
        'is_active': isActive,
      };

  ReconEstimateMapping copyWith({
    String? id,
    String? companyId,
    String? trade,
    String? measurementType,
    String? lineDescription,
    String? materialCategory,
    String? defaultMaterialTier,
    String? unitCode,
    String? quantityFormula,
    double? wasteFactorPct,
    double? roundUpTo,
    String? laborTaskName,
    int? sortOrder,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReconEstimateMapping(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      trade: trade ?? this.trade,
      measurementType: measurementType ?? this.measurementType,
      lineDescription: lineDescription ?? this.lineDescription,
      materialCategory: materialCategory ?? this.materialCategory,
      defaultMaterialTier: defaultMaterialTier ?? this.defaultMaterialTier,
      unitCode: unitCode ?? this.unitCode,
      quantityFormula: quantityFormula ?? this.quantityFormula,
      wasteFactorPct: wasteFactorPct ?? this.wasteFactorPct,
      roundUpTo: roundUpTo ?? this.roundUpTo,
      laborTaskName: laborTaskName ?? this.laborTaskName,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, trade, measurementType, lineDescription];
}

// ════════════════════════════════════════════════════════════════
// RECON MATERIAL RECOMMENDATION
// ════════════════════════════════════════════════════════════════

enum RecommendationSeverity { info, warning, critical }

/// Property-condition-based material recommendation
class ReconMaterialRecommendation extends Equatable {
  final String id;
  final String? companyId;
  final String trade;
  final String conditionField;
  final String conditionOperator;
  final String conditionValue;
  final String recommendationText;
  final String? suggestedMaterialCategory;
  final String? suggestedMaterialTier;
  final String? addLineDescription;
  final String? addLineUnit;
  final String? addLineQuantityFormula;
  final RecommendationSeverity severity;
  final bool isCodeRequired;
  final int sortOrder;
  final bool isActive;
  final DateTime createdAt;

  const ReconMaterialRecommendation({
    required this.id,
    this.companyId,
    required this.trade,
    required this.conditionField,
    required this.conditionOperator,
    required this.conditionValue,
    required this.recommendationText,
    this.suggestedMaterialCategory,
    this.suggestedMaterialTier,
    this.addLineDescription,
    this.addLineUnit,
    this.addLineQuantityFormula,
    this.severity = RecommendationSeverity.info,
    this.isCodeRequired = false,
    this.sortOrder = 0,
    this.isActive = true,
    required this.createdAt,
  });

  bool get isSystemDefault => companyId == null;

  /// Evaluate whether the condition matches against a property value
  bool evaluateCondition(dynamic propertyValue) {
    if (propertyValue == null) return false;

    final pvStr = propertyValue.toString().toLowerCase();
    final cvStr = conditionValue.toLowerCase();

    switch (conditionOperator) {
      case 'eq':
        return pvStr == cvStr;
      case 'ne':
        return pvStr != cvStr;
      case 'gt':
        final pv = double.tryParse(pvStr);
        final cv = double.tryParse(cvStr);
        return pv != null && cv != null && pv > cv;
      case 'lt':
        final pv = double.tryParse(pvStr);
        final cv = double.tryParse(cvStr);
        return pv != null && cv != null && pv < cv;
      case 'gte':
        final pv = double.tryParse(pvStr);
        final cv = double.tryParse(cvStr);
        return pv != null && cv != null && pv >= cv;
      case 'lte':
        final pv = double.tryParse(pvStr);
        final cv = double.tryParse(cvStr);
        return pv != null && cv != null && pv <= cv;
      case 'in':
        final allowedValues = cvStr.split(',').map((s) => s.trim()).toSet();
        return allowedValues.contains(pvStr);
      case 'contains':
        return pvStr.contains(cvStr);
      default:
        return false;
    }
  }

  factory ReconMaterialRecommendation.fromJson(Map<String, dynamic> json) {
    return ReconMaterialRecommendation(
      id: json['id'] as String,
      companyId: json['company_id'] as String?,
      trade: (json['trade'] as String?) ?? '',
      conditionField: (json['condition_field'] as String?) ?? '',
      conditionOperator: (json['condition_operator'] as String?) ?? 'eq',
      conditionValue: (json['condition_value'] as String?) ?? '',
      recommendationText: (json['recommendation_text'] as String?) ?? '',
      suggestedMaterialCategory: json['suggested_material_category'] as String?,
      suggestedMaterialTier: json['suggested_material_tier'] as String?,
      addLineDescription: json['add_line_description'] as String?,
      addLineUnit: json['add_line_unit'] as String?,
      addLineQuantityFormula: json['add_line_quantity_formula'] as String?,
      severity: _parseSeverity(json['severity'] as String?),
      isCodeRequired: json['is_code_required'] == true,
      sortOrder: (json['sort_order'] as int?) ?? 0,
      isActive: json['is_active'] != false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'company_id': companyId,
        'trade': trade,
        'condition_field': conditionField,
        'condition_operator': conditionOperator,
        'condition_value': conditionValue,
        'recommendation_text': recommendationText,
        'suggested_material_category': suggestedMaterialCategory,
        'suggested_material_tier': suggestedMaterialTier,
        'add_line_description': addLineDescription,
        'add_line_unit': addLineUnit,
        'add_line_quantity_formula': addLineQuantityFormula,
        'severity': severity.name,
        'is_code_required': isCodeRequired,
        'sort_order': sortOrder,
        'is_active': isActive,
      };

  @override
  List<Object?> get props => [id, trade, conditionField, conditionOperator];
}

RecommendationSeverity _parseSeverity(String? value) {
  switch (value) {
    case 'warning':
      return RecommendationSeverity.warning;
    case 'critical':
      return RecommendationSeverity.critical;
    default:
      return RecommendationSeverity.info;
  }
}

// ════════════════════════════════════════════════════════════════
// ESTIMATE BUNDLE
// ════════════════════════════════════════════════════════════════

/// Groups multiple estimates for multi-trade proposals
class EstimateBundle extends Equatable {
  final String id;
  final String companyId;
  final String? customerId;
  final String? propertyAddress;
  final String? scanId;
  final String? title;
  final double bundleDiscountPct;
  final double combinedTotal;
  final double discountedTotal;
  final String? notes;
  final List<Map<String, dynamic>> dependencyWarnings;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const EstimateBundle({
    required this.id,
    required this.companyId,
    this.customerId,
    this.propertyAddress,
    this.scanId,
    this.title,
    this.bundleDiscountPct = 0,
    this.combinedTotal = 0,
    this.discountedTotal = 0,
    this.notes,
    this.dependencyWarnings = const [],
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Calculate discounted total
  double get calculatedDiscountedTotal {
    if (bundleDiscountPct <= 0) return combinedTotal;
    return combinedTotal * (1 - bundleDiscountPct / 100);
  }

  /// Savings amount
  double get savings => combinedTotal - discountedTotal;

  factory EstimateBundle.fromJson(Map<String, dynamic> json) {
    return EstimateBundle(
      id: json['id'] as String,
      companyId: (json['company_id'] as String?) ?? '',
      customerId: json['customer_id'] as String?,
      propertyAddress: json['property_address'] as String?,
      scanId: json['scan_id'] as String?,
      title: json['title'] as String?,
      bundleDiscountPct: (json['bundle_discount_pct'] as num?)?.toDouble() ?? 0,
      combinedTotal: (json['combined_total'] as num?)?.toDouble() ?? 0,
      discountedTotal: (json['discounted_total'] as num?)?.toDouble() ?? 0,
      notes: json['notes'] as String?,
      dependencyWarnings: _parseJsonList(json['dependency_warnings']),
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'company_id': companyId,
        'customer_id': customerId,
        'property_address': propertyAddress,
        'scan_id': scanId,
        'title': title,
        'bundle_discount_pct': bundleDiscountPct,
        'combined_total': combinedTotal,
        'discounted_total': discountedTotal,
        'notes': notes,
        'dependency_warnings': dependencyWarnings,
      };

  EstimateBundle copyWith({
    String? id,
    String? companyId,
    String? customerId,
    String? propertyAddress,
    String? scanId,
    String? title,
    double? bundleDiscountPct,
    double? combinedTotal,
    double? discountedTotal,
    String? notes,
    List<Map<String, dynamic>>? dependencyWarnings,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EstimateBundle(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      customerId: customerId ?? this.customerId,
      propertyAddress: propertyAddress ?? this.propertyAddress,
      scanId: scanId ?? this.scanId,
      title: title ?? this.title,
      bundleDiscountPct: bundleDiscountPct ?? this.bundleDiscountPct,
      combinedTotal: combinedTotal ?? this.combinedTotal,
      discountedTotal: discountedTotal ?? this.discountedTotal,
      notes: notes ?? this.notes,
      dependencyWarnings: dependencyWarnings ?? this.dependencyWarnings,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, companyId, combinedTotal];
}

// ════════════════════════════════════════════════════════════════
// CROSS-TRADE DEPENDENCY
// ════════════════════════════════════════════════════════════════

enum DependencyType { before, after, concurrent }

class CrossTradeDependency2 extends Equatable {
  final String id;
  final String primaryTrade;
  final String dependentTrade;
  final DependencyType dependencyType;
  final String warningText;
  final String severity;
  final int sortOrder;

  const CrossTradeDependency2({
    required this.id,
    required this.primaryTrade,
    required this.dependentTrade,
    this.dependencyType = DependencyType.before,
    required this.warningText,
    this.severity = 'info',
    this.sortOrder = 0,
  });

  factory CrossTradeDependency2.fromJson(Map<String, dynamic> json) {
    return CrossTradeDependency2(
      id: json['id'] as String,
      primaryTrade: (json['primary_trade'] as String?) ?? '',
      dependentTrade: (json['dependent_trade'] as String?) ?? '',
      dependencyType: _parseDependencyType(json['dependency_type'] as String?),
      warningText: (json['warning_text'] as String?) ?? '',
      severity: (json['severity'] as String?) ?? 'info',
      sortOrder: (json['sort_order'] as int?) ?? 0,
    );
  }

  @override
  List<Object?> get props => [id, primaryTrade, dependentTrade];
}

DependencyType _parseDependencyType(String? value) {
  switch (value) {
    case 'after':
      return DependencyType.after;
    case 'concurrent':
      return DependencyType.concurrent;
    default:
      return DependencyType.before;
  }
}

// ════════════════════════════════════════════════════════════════
// ESTIMATE CONFIDENCE
// ════════════════════════════════════════════════════════════════

enum ConfidenceLevel { manual, low, medium, high }

class EstimateConfidence {
  final ConfidenceLevel overall;
  final String description;
  final Map<String, ConfidenceLevel> perMeasurement;

  const EstimateConfidence({
    this.overall = ConfidenceLevel.manual,
    this.description = '',
    this.perMeasurement = const {},
  });

  /// Color-coded confidence: green (high), yellow (medium), red (low)
  String get colorCode {
    switch (overall) {
      case ConfidenceLevel.high:
        return 'green';
      case ConfidenceLevel.medium:
        return 'yellow';
      case ConfidenceLevel.low:
        return 'red';
      case ConfidenceLevel.manual:
        return 'blue';
    }
  }

  /// Accuracy range description
  String get accuracyRange {
    switch (overall) {
      case ConfidenceLevel.high:
        return '±5%';
      case ConfidenceLevel.medium:
        return '±15%';
      case ConfidenceLevel.low:
        return '±25%';
      case ConfidenceLevel.manual:
        return 'User-entered';
    }
  }

  factory EstimateConfidence.fromJson(Map<String, dynamic> json) {
    final perMeas = <String, ConfidenceLevel>{};
    final perMeasRaw = json['per_measurement'];
    if (perMeasRaw is Map<String, dynamic>) {
      for (final entry in perMeasRaw.entries) {
        perMeas[entry.key] = _parseConfidenceLevel(entry.value as String?);
      }
    }

    return EstimateConfidence(
      overall: _parseConfidenceLevel(json['overall'] as String?),
      description: (json['description'] as String?) ?? '',
      perMeasurement: perMeas,
    );
  }

  Map<String, dynamic> toJson() => {
        'overall': overall.name,
        'description': description,
        'per_measurement':
            perMeasurement.map((k, v) => MapEntry(k, v.name)),
      };
}

ConfidenceLevel _parseConfidenceLevel(String? value) {
  switch (value) {
    case 'high':
      return ConfidenceLevel.high;
    case 'medium':
      return ConfidenceLevel.medium;
    case 'low':
      return ConfidenceLevel.low;
    default:
      return ConfidenceLevel.manual;
  }
}

// ════════════════════════════════════════════════════════════════
// HELPERS
// ════════════════════════════════════════════════════════════════

List<Map<String, dynamic>> _parseJsonList(dynamic value) {
  if (value == null) return [];
  if (value is List) {
    return value
        .whereType<Map<String, dynamic>>()
        .toList();
  }
  return [];
}
