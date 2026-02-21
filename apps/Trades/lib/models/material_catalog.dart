// ZAFTO Material Catalog Model
// Created: DEPTH29 — Estimate Engine Overhaul
//
// Material catalog with tier system, waste factors, labor hours, supplier URLs.

import 'package:equatable/equatable.dart';

// ════════════════════════════════════════════════════════════════
// TIER ENUM
// ════════════════════════════════════════════════════════════════

enum MaterialTier { economy, standard, premium, elite, luxury }

MaterialTier parseMaterialTier(String? value) {
  switch (value) {
    case 'economy':
      return MaterialTier.economy;
    case 'premium':
      return MaterialTier.premium;
    case 'elite':
      return MaterialTier.elite;
    case 'luxury':
      return MaterialTier.luxury;
    default:
      return MaterialTier.standard;
  }
}

String materialTierToString(MaterialTier tier) {
  switch (tier) {
    case MaterialTier.economy:
      return 'economy';
    case MaterialTier.standard:
      return 'standard';
    case MaterialTier.premium:
      return 'premium';
    case MaterialTier.elite:
      return 'elite';
    case MaterialTier.luxury:
      return 'luxury';
  }
}

String materialTierLabel(MaterialTier tier) {
  switch (tier) {
    case MaterialTier.economy:
      return 'Budget-Friendly';
    case MaterialTier.standard:
      return 'Recommended';
    case MaterialTier.premium:
      return 'Premium';
    case MaterialTier.elite:
      return 'Top-of-Line';
    case MaterialTier.luxury:
      return 'Luxury';
  }
}

// ════════════════════════════════════════════════════════════════
// SUPPLIER URL
// ════════════════════════════════════════════════════════════════

class SupplierUrl extends Equatable {
  final String supplier;
  final String url;
  final double price;

  const SupplierUrl({
    required this.supplier,
    required this.url,
    required this.price,
  });

  factory SupplierUrl.fromJson(Map<String, dynamic> json) {
    return SupplierUrl(
      supplier: json['supplier'] as String? ?? '',
      url: json['url'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'supplier': supplier,
        'url': url,
        'price': price,
      };

  @override
  List<Object?> get props => [supplier, url, price];
}

// ════════════════════════════════════════════════════════════════
// MATERIAL CATALOG ITEM
// ════════════════════════════════════════════════════════════════

class MaterialCatalogItem extends Equatable {
  final String id;
  final String? companyId;
  final String trade;
  final String category;
  final String name;
  final String? brand;
  final String? model;
  final String? sku;
  final MaterialTier tier;
  final String unit;
  final double costPerUnit;
  final double wasteFactorPct;
  final double laborHoursPerUnit;
  final double laborDifficultyMultiplier;
  final int? warrantyYears;
  final String? description;
  final Map<String, dynamic> specsJson;
  final String? photoUrl;
  final List<SupplierUrl> supplierUrls;
  final bool isFavorite;
  final bool isDisabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MaterialCatalogItem({
    required this.id,
    this.companyId,
    required this.trade,
    required this.category,
    required this.name,
    this.brand,
    this.model,
    this.sku,
    required this.tier,
    required this.unit,
    required this.costPerUnit,
    required this.wasteFactorPct,
    required this.laborHoursPerUnit,
    required this.laborDifficultyMultiplier,
    this.warrantyYears,
    this.description,
    this.specsJson = const {},
    this.photoUrl,
    this.supplierUrls = const [],
    this.isFavorite = false,
    this.isDisabled = false,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isSystemDefault => companyId == null;

  /// Material cost with waste factor applied
  double costWithWaste(double quantity) {
    final wasteMultiplier = 1.0 + (wasteFactorPct / 100.0);
    return costPerUnit * quantity * wasteMultiplier;
  }

  /// Total labor hours for a given quantity
  double laborHoursFor(double quantity, {double difficultyMultiplier = 1.0}) {
    return laborHoursPerUnit * quantity * difficultyMultiplier;
  }

  /// Best supplier price (lowest)
  double? get bestPrice {
    if (supplierUrls.isEmpty) return null;
    return supplierUrls
        .map((s) => s.price)
        .where((p) => p > 0)
        .fold<double?>(null, (prev, p) => prev == null || p < prev ? p : prev);
  }

  factory MaterialCatalogItem.fromJson(Map<String, dynamic> json) {
    final suppliers = json['supplier_urls'];
    List<SupplierUrl> parsedSuppliers = [];
    if (suppliers is List) {
      parsedSuppliers =
          suppliers.map((s) => SupplierUrl.fromJson(s as Map<String, dynamic>)).toList();
    }

    return MaterialCatalogItem(
      id: json['id'] as String,
      companyId: json['company_id'] as String?,
      trade: json['trade'] as String,
      category: json['category'] as String,
      name: json['name'] as String,
      brand: json['brand'] as String?,
      model: json['model'] as String?,
      sku: json['sku'] as String?,
      tier: parseMaterialTier(json['tier'] as String?),
      unit: json['unit'] as String,
      costPerUnit: (json['cost_per_unit'] as num?)?.toDouble() ?? 0,
      wasteFactorPct: (json['waste_factor_pct'] as num?)?.toDouble() ?? 10,
      laborHoursPerUnit: (json['labor_hours_per_unit'] as num?)?.toDouble() ?? 0,
      laborDifficultyMultiplier: (json['labor_difficulty_multiplier'] as num?)?.toDouble() ?? 1.0,
      warrantyYears: json['warranty_years'] as int?,
      description: json['description'] as String?,
      specsJson: (json['specs_json'] as Map<String, dynamic>?) ?? {},
      photoUrl: json['photo_url'] as String?,
      supplierUrls: parsedSuppliers,
      isFavorite: json['is_favorite'] == true,
      isDisabled: json['is_disabled'] == true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'company_id': companyId,
        'trade': trade,
        'category': category,
        'name': name,
        'brand': brand,
        'model': model,
        'sku': sku,
        'tier': materialTierToString(tier),
        'unit': unit,
        'cost_per_unit': costPerUnit,
        'waste_factor_pct': wasteFactorPct,
        'labor_hours_per_unit': laborHoursPerUnit,
        'labor_difficulty_multiplier': laborDifficultyMultiplier,
        'warranty_years': warrantyYears,
        'description': description,
        'specs_json': specsJson,
        'photo_url': photoUrl,
        'supplier_urls': supplierUrls.map((s) => s.toJson()).toList(),
        'is_favorite': isFavorite,
        'is_disabled': isDisabled,
      };

  MaterialCatalogItem copyWith({
    String? id,
    String? companyId,
    String? trade,
    String? category,
    String? name,
    String? brand,
    String? model,
    String? sku,
    MaterialTier? tier,
    String? unit,
    double? costPerUnit,
    double? wasteFactorPct,
    double? laborHoursPerUnit,
    double? laborDifficultyMultiplier,
    int? warrantyYears,
    String? description,
    Map<String, dynamic>? specsJson,
    String? photoUrl,
    List<SupplierUrl>? supplierUrls,
    bool? isFavorite,
    bool? isDisabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MaterialCatalogItem(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      trade: trade ?? this.trade,
      category: category ?? this.category,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      sku: sku ?? this.sku,
      tier: tier ?? this.tier,
      unit: unit ?? this.unit,
      costPerUnit: costPerUnit ?? this.costPerUnit,
      wasteFactorPct: wasteFactorPct ?? this.wasteFactorPct,
      laborHoursPerUnit: laborHoursPerUnit ?? this.laborHoursPerUnit,
      laborDifficultyMultiplier: laborDifficultyMultiplier ?? this.laborDifficultyMultiplier,
      warrantyYears: warrantyYears ?? this.warrantyYears,
      description: description ?? this.description,
      specsJson: specsJson ?? this.specsJson,
      photoUrl: photoUrl ?? this.photoUrl,
      supplierUrls: supplierUrls ?? this.supplierUrls,
      isFavorite: isFavorite ?? this.isFavorite,
      isDisabled: isDisabled ?? this.isDisabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        companyId,
        trade,
        category,
        name,
        brand,
        model,
        sku,
        tier,
        unit,
        costPerUnit,
        wasteFactorPct,
        laborHoursPerUnit,
        laborDifficultyMultiplier,
        warrantyYears,
        description,
        photoUrl,
        isFavorite,
        isDisabled,
      ];
}
