import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Template line item for quick bid creation
class TemplateLineItem extends Equatable {
  final String id;
  final String description;
  final String unit; // 'each', 'hour', 'foot', 'sqft'
  final double defaultQuantity;
  final double defaultUnitPrice;
  final bool isTaxable;
  final String? category; // 'labor', 'materials', 'equipment', 'permits'
  final List<String> tags; // For filtering/searching
  final int sortOrder;

  const TemplateLineItem({
    required this.id,
    required this.description,
    this.unit = 'each',
    this.defaultQuantity = 1.0,
    required this.defaultUnitPrice,
    this.isTaxable = true,
    this.category,
    this.tags = const [],
    this.sortOrder = 0,
  });

  @override
  List<Object?> get props => [id, description, defaultUnitPrice];

  Map<String, dynamic> toMap() => {
        'id': id,
        'description': description,
        'unit': unit,
        'defaultQuantity': defaultQuantity,
        'defaultUnitPrice': defaultUnitPrice,
        'isTaxable': isTaxable,
        'category': category,
        'tags': tags,
        'sortOrder': sortOrder,
      };

  factory TemplateLineItem.fromMap(Map<String, dynamic> map) => TemplateLineItem(
        id: map['id'] as String,
        description: map['description'] as String,
        unit: map['unit'] as String? ?? 'each',
        defaultQuantity: (map['defaultQuantity'] as num?)?.toDouble() ?? 1.0,
        defaultUnitPrice: (map['defaultUnitPrice'] as num).toDouble(),
        isTaxable: map['isTaxable'] as bool? ?? true,
        category: map['category'] as String?,
        tags: List<String>.from(map['tags'] ?? []),
        sortOrder: map['sortOrder'] as int? ?? 0,
      );

  TemplateLineItem copyWith({
    String? id,
    String? description,
    String? unit,
    double? defaultQuantity,
    double? defaultUnitPrice,
    bool? isTaxable,
    String? category,
    List<String>? tags,
    int? sortOrder,
  }) {
    return TemplateLineItem(
      id: id ?? this.id,
      description: description ?? this.description,
      unit: unit ?? this.unit,
      defaultQuantity: defaultQuantity ?? this.defaultQuantity,
      defaultUnitPrice: defaultUnitPrice ?? this.defaultUnitPrice,
      isTaxable: isTaxable ?? this.isTaxable,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}

/// Template add-on for optional upsells
class TemplateAddOn extends Equatable {
  final String id;
  final String name;
  final String? description;
  final double defaultPrice;
  final int sortOrder;

  const TemplateAddOn({
    required this.id,
    required this.name,
    this.description,
    required this.defaultPrice,
    this.sortOrder = 0,
  });

  @override
  List<Object?> get props => [id, name, defaultPrice];

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'defaultPrice': defaultPrice,
        'sortOrder': sortOrder,
      };

  factory TemplateAddOn.fromMap(Map<String, dynamic> map) => TemplateAddOn(
        id: map['id'] as String,
        name: map['name'] as String,
        description: map['description'] as String?,
        defaultPrice: (map['defaultPrice'] as num).toDouble(),
        sortOrder: map['sortOrder'] as int? ?? 0,
      );
}

/// Bid template for a specific trade/service type
class BidTemplate extends Equatable {
  final String id;
  final String companyId; // null for system templates
  final String name;
  final String? description;
  final String tradeType; // 'electrical', 'plumbing', 'hvac', etc.
  final String? category; // 'residential', 'commercial', 'service call'

  // Template content
  final List<TemplateLineItem> lineItems;
  final List<TemplateAddOn> addOns;

  // Default settings
  final double defaultTaxRate;
  final double defaultDepositPercent;
  final int defaultValidityDays;
  final String? defaultTerms;
  final String? defaultScopeOfWork;

  // Good/Better/Best presets
  final bool hasGoodBetterBest;
  final String? goodDescription;
  final String? betterDescription;
  final String? bestDescription;
  final double betterMultiplier; // e.g., 1.3 for 30% more than Good
  final double bestMultiplier; // e.g., 1.6 for 60% more than Good

  // Metadata
  final bool isSystemTemplate; // Built-in vs user-created
  final bool isActive;
  final int useCount; // Track popularity
  final DateTime createdAt;
  final DateTime updatedAt;

  const BidTemplate({
    required this.id,
    required this.companyId,
    required this.name,
    this.description,
    required this.tradeType,
    this.category,
    this.lineItems = const [],
    this.addOns = const [],
    this.defaultTaxRate = 0.0,
    this.defaultDepositPercent = 50.0,
    this.defaultValidityDays = 30,
    this.defaultTerms,
    this.defaultScopeOfWork,
    this.hasGoodBetterBest = true,
    this.goodDescription,
    this.betterDescription,
    this.bestDescription,
    this.betterMultiplier = 1.3,
    this.bestMultiplier = 1.6,
    this.isSystemTemplate = false,
    this.isActive = true,
    this.useCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [id, companyId, name, tradeType];

  // ============================================================
  // COMPUTED PROPERTIES
  // ============================================================

  /// Get display name with trade type
  String get displayName => name;

  /// Check if template can be edited (not system template)
  bool get isEditable => !isSystemTemplate;

  /// Get line items by category
  List<TemplateLineItem> getLineItemsByCategory(String category) {
    return lineItems.where((item) => item.category == category).toList();
  }

  /// Get labor items
  List<TemplateLineItem> get laborItems => getLineItemsByCategory('labor');

  /// Get material items
  List<TemplateLineItem> get materialItems => getLineItemsByCategory('materials');

  /// Get equipment items
  List<TemplateLineItem> get equipmentItems => getLineItemsByCategory('equipment');

  // ============================================================
  // SERIALIZATION
  // ============================================================

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'name': name,
      'description': description,
      'tradeType': tradeType,
      'category': category,
      'lineItems': lineItems.map((e) => e.toMap()).toList(),
      'addOns': addOns.map((e) => e.toMap()).toList(),
      'defaultTaxRate': defaultTaxRate,
      'defaultDepositPercent': defaultDepositPercent,
      'defaultValidityDays': defaultValidityDays,
      'defaultTerms': defaultTerms,
      'defaultScopeOfWork': defaultScopeOfWork,
      'hasGoodBetterBest': hasGoodBetterBest,
      'goodDescription': goodDescription,
      'betterDescription': betterDescription,
      'bestDescription': bestDescription,
      'betterMultiplier': betterMultiplier,
      'bestMultiplier': bestMultiplier,
      'isSystemTemplate': isSystemTemplate,
      'isActive': isActive,
      'useCount': useCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory BidTemplate.fromMap(Map<String, dynamic> map) {
    return BidTemplate(
      id: map['id'] as String,
      companyId: map['companyId'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      tradeType: map['tradeType'] as String,
      category: map['category'] as String?,
      lineItems: (map['lineItems'] as List<dynamic>?)
              ?.map((e) => TemplateLineItem.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      addOns: (map['addOns'] as List<dynamic>?)
              ?.map((e) => TemplateAddOn.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      defaultTaxRate: (map['defaultTaxRate'] as num?)?.toDouble() ?? 0.0,
      defaultDepositPercent:
          (map['defaultDepositPercent'] as num?)?.toDouble() ?? 50.0,
      defaultValidityDays: map['defaultValidityDays'] as int? ?? 30,
      defaultTerms: map['defaultTerms'] as String?,
      defaultScopeOfWork: map['defaultScopeOfWork'] as String?,
      hasGoodBetterBest: map['hasGoodBetterBest'] as bool? ?? true,
      goodDescription: map['goodDescription'] as String?,
      betterDescription: map['betterDescription'] as String?,
      bestDescription: map['bestDescription'] as String?,
      betterMultiplier: (map['betterMultiplier'] as num?)?.toDouble() ?? 1.3,
      bestMultiplier: (map['bestMultiplier'] as num?)?.toDouble() ?? 1.6,
      isSystemTemplate: map['isSystemTemplate'] as bool? ?? false,
      isActive: map['isActive'] as bool? ?? true,
      useCount: map['useCount'] as int? ?? 0,
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
    );
  }

  factory BidTemplate.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BidTemplate.fromMap({...data, 'id': doc.id});
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  BidTemplate copyWith({
    String? id,
    String? companyId,
    String? name,
    String? description,
    String? tradeType,
    String? category,
    List<TemplateLineItem>? lineItems,
    List<TemplateAddOn>? addOns,
    double? defaultTaxRate,
    double? defaultDepositPercent,
    int? defaultValidityDays,
    String? defaultTerms,
    String? defaultScopeOfWork,
    bool? hasGoodBetterBest,
    String? goodDescription,
    String? betterDescription,
    String? bestDescription,
    double? betterMultiplier,
    double? bestMultiplier,
    bool? isSystemTemplate,
    bool? isActive,
    int? useCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BidTemplate(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      name: name ?? this.name,
      description: description ?? this.description,
      tradeType: tradeType ?? this.tradeType,
      category: category ?? this.category,
      lineItems: lineItems ?? this.lineItems,
      addOns: addOns ?? this.addOns,
      defaultTaxRate: defaultTaxRate ?? this.defaultTaxRate,
      defaultDepositPercent: defaultDepositPercent ?? this.defaultDepositPercent,
      defaultValidityDays: defaultValidityDays ?? this.defaultValidityDays,
      defaultTerms: defaultTerms ?? this.defaultTerms,
      defaultScopeOfWork: defaultScopeOfWork ?? this.defaultScopeOfWork,
      hasGoodBetterBest: hasGoodBetterBest ?? this.hasGoodBetterBest,
      goodDescription: goodDescription ?? this.goodDescription,
      betterDescription: betterDescription ?? this.betterDescription,
      bestDescription: bestDescription ?? this.bestDescription,
      betterMultiplier: betterMultiplier ?? this.betterMultiplier,
      bestMultiplier: bestMultiplier ?? this.bestMultiplier,
      isSystemTemplate: isSystemTemplate ?? this.isSystemTemplate,
      isActive: isActive ?? this.isActive,
      useCount: useCount ?? this.useCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // ============================================================
  // FACTORY CONSTRUCTORS
  // ============================================================

  /// Create a new custom template
  factory BidTemplate.create({
    required String id,
    required String companyId,
    required String name,
    required String tradeType,
    String? description,
    String? category,
  }) {
    final now = DateTime.now();
    return BidTemplate(
      id: id,
      companyId: companyId,
      name: name,
      description: description,
      tradeType: tradeType,
      category: category,
      createdAt: now,
      updatedAt: now,
    );
  }
}

/// Line item library - master list of all possible line items per trade
class LineItemLibrary extends Equatable {
  final String tradeType;
  final List<TemplateLineItem> items;
  final DateTime lastUpdated;

  const LineItemLibrary({
    required this.tradeType,
    required this.items,
    required this.lastUpdated,
  });

  @override
  List<Object?> get props => [tradeType, items.length];

  Map<String, dynamic> toMap() => {
        'tradeType': tradeType,
        'items': items.map((e) => e.toMap()).toList(),
        'lastUpdated': lastUpdated.toIso8601String(),
      };

  factory LineItemLibrary.fromMap(Map<String, dynamic> map) => LineItemLibrary(
        tradeType: map['tradeType'] as String,
        items: (map['items'] as List<dynamic>)
            .map((e) => TemplateLineItem.fromMap(e as Map<String, dynamic>))
            .toList(),
        lastUpdated: DateTime.parse(map['lastUpdated'] as String),
      );

  /// Get items by category
  List<TemplateLineItem> getByCategory(String category) {
    return items.where((item) => item.category == category).toList();
  }

  /// Search items by description
  List<TemplateLineItem> search(String query) {
    final lowerQuery = query.toLowerCase();
    return items.where((item) {
      return item.description.toLowerCase().contains(lowerQuery) ||
          item.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
    }).toList();
  }
}
