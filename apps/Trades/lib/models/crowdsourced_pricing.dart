// ZAFTO Crowdsourced Material Pricing Intelligence Models
// Created: DEPTH31 — Receipt OCR, Supplier Directory, Pricing Engine
//
// Models for material_receipts, material_receipt_items, material_price_index,
// supplier_directory, distributor_accounts, price_alerts, regional_cost_factors,
// material_price_indices, pricing_contributor_status.

import 'package:equatable/equatable.dart';

// ════════════════════════════════════════════════════════════════
// ENUMS
// ════════════════════════════════════════════════════════════════

enum SupplierType {
  bigBox,
  specialtyDistributor,
  supplyHouse,
  online,
  localYard,
  manufacturerDirect,
  equipmentRental,
  unknown;

  static SupplierType fromString(String? value) {
    switch (value) {
      case 'big_box': return bigBox;
      case 'specialty_distributor': return specialtyDistributor;
      case 'supply_house': return supplyHouse;
      case 'online': return online;
      case 'local_yard': return localYard;
      case 'manufacturer_direct': return manufacturerDirect;
      case 'equipment_rental': return equipmentRental;
      default: return unknown;
    }
  }

  String toJson() {
    switch (this) {
      case bigBox: return 'big_box';
      case specialtyDistributor: return 'specialty_distributor';
      case supplyHouse: return 'supply_house';
      case online: return 'online';
      case localYard: return 'local_yard';
      case manufacturerDirect: return 'manufacturer_direct';
      case equipmentRental: return 'equipment_rental';
      case unknown: return 'unknown';
    }
  }
}

enum PricingTier {
  retail,
  wholesale,
  accountOnly,
  mixed;

  static PricingTier fromString(String? value) {
    switch (value) {
      case 'retail': return retail;
      case 'wholesale': return wholesale;
      case 'account_only': return accountOnly;
      case 'mixed': return mixed;
      default: return retail;
    }
  }

  String toJson() {
    switch (this) {
      case retail: return 'retail';
      case wholesale: return 'wholesale';
      case accountOnly: return 'account_only';
      case mixed: return 'mixed';
    }
  }
}

enum ReceiptProcessingStatus {
  pending,
  processing,
  processed,
  needsReview,
  failed;

  static ReceiptProcessingStatus fromString(String? value) {
    switch (value) {
      case 'pending': return pending;
      case 'processing': return processing;
      case 'processed': return processed;
      case 'needs_review': return needsReview;
      case 'failed': return failed;
      default: return pending;
    }
  }

  String toJson() {
    switch (this) {
      case pending: return 'pending';
      case processing: return 'processing';
      case processed: return 'processed';
      case needsReview: return 'needs_review';
      case failed: return 'failed';
    }
  }
}

enum ReceiptSource {
  upload,
  camera,
  emailForward,
  zbooksSync;

  static ReceiptSource fromString(String? value) {
    switch (value) {
      case 'upload': return upload;
      case 'camera': return camera;
      case 'email_forward': return emailForward;
      case 'zbooks_sync': return zbooksSync;
      default: return upload;
    }
  }

  String toJson() {
    switch (this) {
      case upload: return 'upload';
      case camera: return 'camera';
      case emailForward: return 'email_forward';
      case zbooksSync: return 'zbooks_sync';
    }
  }
}

enum ReceiptItemUnit {
  each,
  ft,
  lf,
  sqft,
  sq,
  bundle,
  box,
  roll,
  bag,
  gallon,
  lb,
  yd,
  cuyd,
  sheet,
  pair,
  set,
  caseUnit,
  pallet,
  ton,
  other;

  static ReceiptItemUnit fromString(String? value) {
    switch (value) {
      case 'each': return each;
      case 'ft': return ft;
      case 'lf': return lf;
      case 'sqft': return sqft;
      case 'sq': return sq;
      case 'bundle': return bundle;
      case 'box': return box;
      case 'roll': return roll;
      case 'bag': return bag;
      case 'gallon': return gallon;
      case 'lb': return lb;
      case 'yd': return yd;
      case 'cuyd': return cuyd;
      case 'sheet': return sheet;
      case 'pair': return pair;
      case 'set': return set;
      case 'case': return caseUnit;
      case 'pallet': return pallet;
      case 'ton': return ton;
      default: return other;
    }
  }

  String toJson() {
    switch (this) {
      case each: return 'each';
      case ft: return 'ft';
      case lf: return 'lf';
      case sqft: return 'sqft';
      case sq: return 'sq';
      case bundle: return 'bundle';
      case box: return 'box';
      case roll: return 'roll';
      case bag: return 'bag';
      case gallon: return 'gallon';
      case lb: return 'lb';
      case yd: return 'yd';
      case cuyd: return 'cuyd';
      case sheet: return 'sheet';
      case pair: return 'pair';
      case set: return 'set';
      case caseUnit: return 'case';
      case pallet: return 'pallet';
      case ton: return 'ton';
      case other: return 'other';
    }
  }
}

enum ConnectionStatus {
  pending,
  connected,
  disconnected,
  error,
  expired;

  static ConnectionStatus fromString(String? value) {
    switch (value) {
      case 'pending': return pending;
      case 'connected': return connected;
      case 'disconnected': return disconnected;
      case 'error': return error;
      case 'expired': return expired;
      default: return pending;
    }
  }

  String toJson() {
    switch (this) {
      case pending: return 'pending';
      case connected: return 'connected';
      case disconnected: return 'disconnected';
      case error: return 'error';
      case expired: return 'expired';
    }
  }
}

enum AlertType {
  belowPrice,
  priceDropPct,
  backInStock;

  static AlertType fromString(String? value) {
    switch (value) {
      case 'below_price': return belowPrice;
      case 'price_drop_pct': return priceDropPct;
      case 'back_in_stock': return backInStock;
      default: return belowPrice;
    }
  }

  String toJson() {
    switch (this) {
      case belowPrice: return 'below_price';
      case priceDropPct: return 'price_drop_pct';
      case backInStock: return 'back_in_stock';
    }
  }
}

enum ContributorBadge {
  none,
  bronze,
  silver,
  gold,
  platinum;

  static ContributorBadge fromString(String? value) {
    switch (value) {
      case 'bronze': return bronze;
      case 'silver': return silver;
      case 'gold': return gold;
      case 'platinum': return platinum;
      default: return none;
    }
  }

  String toJson() {
    switch (this) {
      case none: return 'none';
      case bronze: return 'bronze';
      case silver: return 'silver';
      case gold: return 'gold';
      case platinum: return 'platinum';
    }
  }

  String get displayName {
    switch (this) {
      case none: return 'Not Contributing';
      case bronze: return 'Bronze Contributor';
      case silver: return 'Silver Contributor';
      case gold: return 'Gold Contributor';
      case platinum: return 'Platinum Contributor';
    }
  }
}

// ════════════════════════════════════════════════════════════════
// SUPPLIER DIRECTORY
// ════════════════════════════════════════════════════════════════

class SupplierDirectory extends Equatable {
  final String id;
  final String name;
  final String nameNormalized;
  final List<String> aliases;
  final SupplierType supplierType;
  final List<String> tradesServed;
  final String? website;
  final String? phone;
  final List<String> locationsApproximate;
  final PricingTier pricingTier;
  final double? avgDiscountFromRetailPct;
  final int receiptCount;
  final bool hasApi;
  final String? apiType;
  final String? affiliateNetwork;
  final DateTime firstSeenAt;
  final DateTime lastSeenAt;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SupplierDirectory({
    required this.id,
    required this.name,
    required this.nameNormalized,
    this.aliases = const [],
    this.supplierType = SupplierType.unknown,
    this.tradesServed = const [],
    this.website,
    this.phone,
    this.locationsApproximate = const [],
    this.pricingTier = PricingTier.retail,
    this.avgDiscountFromRetailPct,
    this.receiptCount = 0,
    this.hasApi = false,
    this.apiType,
    this.affiliateNetwork,
    required this.firstSeenAt,
    required this.lastSeenAt,
    this.isVerified = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SupplierDirectory.fromJson(Map<String, dynamic> json) {
    return SupplierDirectory(
      id: json['id'] as String,
      name: json['name'] as String,
      nameNormalized: json['name_normalized'] as String,
      aliases: _parseStringList(json['aliases']),
      supplierType: SupplierType.fromString(json['supplier_type'] as String?),
      tradesServed: _parseStringList(json['trades_served']),
      website: json['website'] as String?,
      phone: json['phone'] as String?,
      locationsApproximate: _parseStringList(json['locations_approximate']),
      pricingTier: PricingTier.fromString(json['pricing_tier'] as String?),
      avgDiscountFromRetailPct: _parseDouble(json['avg_discount_from_retail_pct']),
      receiptCount: (json['receipt_count'] as num?)?.toInt() ?? 0,
      hasApi: json['has_api'] as bool? ?? false,
      apiType: json['api_type'] as String?,
      affiliateNetwork: json['affiliate_network'] as String?,
      firstSeenAt: DateTime.parse(json['first_seen_at'] as String),
      lastSeenAt: DateTime.parse(json['last_seen_at'] as String),
      isVerified: json['is_verified'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'name_normalized': nameNormalized,
    'aliases': aliases,
    'supplier_type': supplierType.toJson(),
    'trades_served': tradesServed,
    'website': website,
    'phone': phone,
    'locations_approximate': locationsApproximate,
    'pricing_tier': pricingTier.toJson(),
    'avg_discount_from_retail_pct': avgDiscountFromRetailPct,
    'receipt_count': receiptCount,
    'has_api': hasApi,
    'api_type': apiType,
    'affiliate_network': affiliateNetwork,
    'is_verified': isVerified,
  };

  @override
  List<Object?> get props => [id, name, nameNormalized, updatedAt];
}

// ════════════════════════════════════════════════════════════════
// MATERIAL RECEIPT
// ════════════════════════════════════════════════════════════════

class MaterialReceipt extends Equatable {
  final String id;
  final String companyId;
  final String uploadedBy;
  final String? supplierId;
  final String? supplierNameRaw;
  final String? supplierAddress;
  final DateTime? receiptDate;
  final double? subtotal;
  final double? tax;
  final double? total;
  final String? paymentMethod;
  final String? receiptImageUrl;
  final String? ocrRawText;
  final double? ocrConfidence;
  final ReceiptProcessingStatus processingStatus;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? linkedJobId;
  final String? linkedExpenseId;
  final ReceiptSource source;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MaterialReceipt({
    required this.id,
    required this.companyId,
    required this.uploadedBy,
    this.supplierId,
    this.supplierNameRaw,
    this.supplierAddress,
    this.receiptDate,
    this.subtotal,
    this.tax,
    this.total,
    this.paymentMethod,
    this.receiptImageUrl,
    this.ocrRawText,
    this.ocrConfidence,
    this.processingStatus = ReceiptProcessingStatus.pending,
    this.reviewedBy,
    this.reviewedAt,
    this.linkedJobId,
    this.linkedExpenseId,
    this.source = ReceiptSource.upload,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get needsReview => processingStatus == ReceiptProcessingStatus.needsReview;
  bool get isProcessed => processingStatus == ReceiptProcessingStatus.processed;
  bool get hasFailed => processingStatus == ReceiptProcessingStatus.failed;
  int get itemCount => 0; // Populated from join

  factory MaterialReceipt.fromJson(Map<String, dynamic> json) {
    return MaterialReceipt(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      uploadedBy: json['uploaded_by'] as String,
      supplierId: json['supplier_id'] as String?,
      supplierNameRaw: json['supplier_name_raw'] as String?,
      supplierAddress: json['supplier_address'] as String?,
      receiptDate: json['receipt_date'] != null
          ? DateTime.parse(json['receipt_date'] as String)
          : null,
      subtotal: _parseDouble(json['subtotal']),
      tax: _parseDouble(json['tax']),
      total: _parseDouble(json['total']),
      paymentMethod: json['payment_method'] as String?,
      receiptImageUrl: json['receipt_image_url'] as String?,
      ocrRawText: json['ocr_raw_text'] as String?,
      ocrConfidence: _parseDouble(json['ocr_confidence']),
      processingStatus: ReceiptProcessingStatus.fromString(json['processing_status'] as String?),
      reviewedBy: json['reviewed_by'] as String?,
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.parse(json['reviewed_at'] as String)
          : null,
      linkedJobId: json['linked_job_id'] as String?,
      linkedExpenseId: json['linked_expense_id'] as String?,
      source: ReceiptSource.fromString(json['source'] as String?),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'company_id': companyId,
    'uploaded_by': uploadedBy,
    'supplier_id': supplierId,
    'supplier_name_raw': supplierNameRaw,
    'supplier_address': supplierAddress,
    'receipt_date': receiptDate?.toIso8601String().split('T').first,
    'subtotal': subtotal,
    'tax': tax,
    'total': total,
    'payment_method': paymentMethod,
    'receipt_image_url': receiptImageUrl,
    'ocr_raw_text': ocrRawText,
    'ocr_confidence': ocrConfidence,
    'processing_status': processingStatus.toJson(),
    'reviewed_by': reviewedBy,
    'reviewed_at': reviewedAt?.toUtc().toIso8601String(),
    'linked_job_id': linkedJobId,
    'linked_expense_id': linkedExpenseId,
    'source': source.toJson(),
  };

  MaterialReceipt copyWith({
    String? supplierId,
    String? supplierNameRaw,
    ReceiptProcessingStatus? processingStatus,
    String? reviewedBy,
    DateTime? reviewedAt,
    String? linkedJobId,
  }) {
    return MaterialReceipt(
      id: id,
      companyId: companyId,
      uploadedBy: uploadedBy,
      supplierId: supplierId ?? this.supplierId,
      supplierNameRaw: supplierNameRaw ?? this.supplierNameRaw,
      supplierAddress: supplierAddress,
      receiptDate: receiptDate,
      subtotal: subtotal,
      tax: tax,
      total: total,
      paymentMethod: paymentMethod,
      receiptImageUrl: receiptImageUrl,
      ocrRawText: ocrRawText,
      ocrConfidence: ocrConfidence,
      processingStatus: processingStatus ?? this.processingStatus,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      linkedJobId: linkedJobId ?? this.linkedJobId,
      linkedExpenseId: linkedExpenseId,
      source: source,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, companyId, processingStatus, updatedAt];
}

// ════════════════════════════════════════════════════════════════
// MATERIAL RECEIPT ITEM (line item from a receipt)
// ════════════════════════════════════════════════════════════════

class MaterialReceiptItem extends Equatable {
  final String id;
  final String receiptId;
  final String companyId;
  final String? descriptionRaw;
  final String? descriptionNormalized;
  final String? sku;
  final String? upc;
  final String? brand;
  final String? productNameNormalized;
  final String? materialCategory;
  final String? trade;
  final double quantity;
  final ReceiptItemUnit unit;
  final double? unitPrice;
  final double? total;
  final double? ocrConfidence;
  final bool manuallyCorrected;
  final String? correctionSource;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MaterialReceiptItem({
    required this.id,
    required this.receiptId,
    required this.companyId,
    this.descriptionRaw,
    this.descriptionNormalized,
    this.sku,
    this.upc,
    this.brand,
    this.productNameNormalized,
    this.materialCategory,
    this.trade,
    this.quantity = 1,
    this.unit = ReceiptItemUnit.each,
    this.unitPrice,
    this.total,
    this.ocrConfidence,
    this.manuallyCorrected = false,
    this.correctionSource,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get hasLowConfidence => (ocrConfidence ?? 0) < 80;

  factory MaterialReceiptItem.fromJson(Map<String, dynamic> json) {
    return MaterialReceiptItem(
      id: json['id'] as String,
      receiptId: json['receipt_id'] as String,
      companyId: json['company_id'] as String,
      descriptionRaw: json['description_raw'] as String?,
      descriptionNormalized: json['description_normalized'] as String?,
      sku: json['sku'] as String?,
      upc: json['upc'] as String?,
      brand: json['brand'] as String?,
      productNameNormalized: json['product_name_normalized'] as String?,
      materialCategory: json['material_category'] as String?,
      trade: json['trade'] as String?,
      quantity: _parseDouble(json['quantity']) ?? 1,
      unit: ReceiptItemUnit.fromString(json['unit'] as String?),
      unitPrice: _parseDouble(json['unit_price']),
      total: _parseDouble(json['total']),
      ocrConfidence: _parseDouble(json['ocr_confidence']),
      manuallyCorrected: json['manually_corrected'] as bool? ?? false,
      correctionSource: json['correction_source'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'receipt_id': receiptId,
    'company_id': companyId,
    'description_raw': descriptionRaw,
    'description_normalized': descriptionNormalized,
    'sku': sku,
    'upc': upc,
    'brand': brand,
    'product_name_normalized': productNameNormalized,
    'material_category': materialCategory,
    'trade': trade,
    'quantity': quantity,
    'unit': unit.toJson(),
    'unit_price': unitPrice,
    'total': total,
    'ocr_confidence': ocrConfidence,
    'manually_corrected': manuallyCorrected,
    'correction_source': correctionSource,
  };

  MaterialReceiptItem copyWith({
    String? descriptionNormalized,
    String? productNameNormalized,
    String? materialCategory,
    String? trade,
    double? quantity,
    ReceiptItemUnit? unit,
    double? unitPrice,
    double? total,
    bool? manuallyCorrected,
  }) {
    return MaterialReceiptItem(
      id: id,
      receiptId: receiptId,
      companyId: companyId,
      descriptionRaw: descriptionRaw,
      descriptionNormalized: descriptionNormalized ?? this.descriptionNormalized,
      sku: sku,
      upc: upc,
      brand: brand,
      productNameNormalized: productNameNormalized ?? this.productNameNormalized,
      materialCategory: materialCategory ?? this.materialCategory,
      trade: trade ?? this.trade,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      unitPrice: unitPrice ?? this.unitPrice,
      total: total ?? this.total,
      ocrConfidence: ocrConfidence,
      manuallyCorrected: manuallyCorrected ?? this.manuallyCorrected,
      correctionSource: correctionSource,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, receiptId, productNameNormalized, updatedAt];
}

// ════════════════════════════════════════════════════════════════
// MATERIAL PRICE INDEX (anonymized aggregate)
// ════════════════════════════════════════════════════════════════

class MaterialPriceIndex extends Equatable {
  final String id;
  final String productNameNormalized;
  final String materialCategory;
  final String? trade;
  final String? brand;
  final String? skuCommon;
  final String? upcCommon;
  final String unit;
  final double? avgPriceNational;
  final Map<String, dynamic> avgPriceByMetro;
  final double? priceLow;
  final double? priceHigh;
  final double? priceMedian;
  final int sampleCount;
  final bool isPublished;
  final DateTime lastUpdated;
  final double? trend30dPct;
  final double? trend90dPct;
  final double? trend12mPct;
  final List<dynamic> priceHistory;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MaterialPriceIndex({
    required this.id,
    required this.productNameNormalized,
    required this.materialCategory,
    this.trade,
    this.brand,
    this.skuCommon,
    this.upcCommon,
    this.unit = 'each',
    this.avgPriceNational,
    this.avgPriceByMetro = const {},
    this.priceLow,
    this.priceHigh,
    this.priceMedian,
    this.sampleCount = 0,
    this.isPublished = false,
    required this.lastUpdated,
    this.trend30dPct,
    this.trend90dPct,
    this.trend12mPct,
    this.priceHistory = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isTrendingUp => (trend30dPct ?? 0) > 5;
  bool get isTrendingDown => (trend30dPct ?? 0) < -5;
  double get priceSpread => (priceHigh ?? 0) - (priceLow ?? 0);

  factory MaterialPriceIndex.fromJson(Map<String, dynamic> json) {
    return MaterialPriceIndex(
      id: json['id'] as String,
      productNameNormalized: json['product_name_normalized'] as String,
      materialCategory: json['material_category'] as String,
      trade: json['trade'] as String?,
      brand: json['brand'] as String?,
      skuCommon: json['sku_common'] as String?,
      upcCommon: json['upc_common'] as String?,
      unit: json['unit'] as String? ?? 'each',
      avgPriceNational: _parseDouble(json['avg_price_national']),
      avgPriceByMetro: json['avg_price_by_metro'] as Map<String, dynamic>? ?? {},
      priceLow: _parseDouble(json['price_low']),
      priceHigh: _parseDouble(json['price_high']),
      priceMedian: _parseDouble(json['price_median']),
      sampleCount: (json['sample_count'] as num?)?.toInt() ?? 0,
      isPublished: json['is_published'] as bool? ?? false,
      lastUpdated: DateTime.parse(json['last_updated'] as String),
      trend30dPct: _parseDouble(json['trend_30d_pct']),
      trend90dPct: _parseDouble(json['trend_90d_pct']),
      trend12mPct: _parseDouble(json['trend_12m_pct']),
      priceHistory: json['price_history'] as List<dynamic>? ?? [],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'product_name_normalized': productNameNormalized,
    'material_category': materialCategory,
    'trade': trade,
    'brand': brand,
    'sku_common': skuCommon,
    'upc_common': upcCommon,
    'unit': unit,
    'avg_price_national': avgPriceNational,
    'avg_price_by_metro': avgPriceByMetro,
    'price_low': priceLow,
    'price_high': priceHigh,
    'price_median': priceMedian,
    'sample_count': sampleCount,
    'is_published': isPublished,
    'trend_30d_pct': trend30dPct,
    'trend_90d_pct': trend90dPct,
    'trend_12m_pct': trend12mPct,
    'price_history': priceHistory,
  };

  @override
  List<Object?> get props => [id, productNameNormalized, materialCategory, updatedAt];
}

// ════════════════════════════════════════════════════════════════
// MATERIAL PRICE INDEX ENTRY (BLS/FRED PPI)
// ════════════════════════════════════════════════════════════════

class MaterialPriceIndexEntry extends Equatable {
  final String id;
  final String seriesId;
  final String category;
  final String? region;
  final DateTime date;
  final double value;
  final double? pctChange1mo;
  final double? pctChange12mo;
  final String source;
  final DateTime createdAt;

  const MaterialPriceIndexEntry({
    required this.id,
    required this.seriesId,
    required this.category,
    this.region,
    required this.date,
    required this.value,
    this.pctChange1mo,
    this.pctChange12mo,
    this.source = 'bls',
    required this.createdAt,
  });

  factory MaterialPriceIndexEntry.fromJson(Map<String, dynamic> json) {
    return MaterialPriceIndexEntry(
      id: json['id'] as String,
      seriesId: json['series_id'] as String,
      category: json['category'] as String,
      region: json['region'] as String?,
      date: DateTime.parse(json['date'] as String),
      value: _parseDouble(json['value']) ?? 0,
      pctChange1mo: _parseDouble(json['pct_change_1mo']),
      pctChange12mo: _parseDouble(json['pct_change_12mo']),
      source: json['source'] as String? ?? 'bls',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  @override
  List<Object?> get props => [id, seriesId, date];
}

// ════════════════════════════════════════════════════════════════
// REGIONAL COST FACTOR
// ════════════════════════════════════════════════════════════════

class RegionalCostFactor extends Equatable {
  final String id;
  final String state;
  final String? metroArea;
  final String? trade;
  final double multiplier;
  final double? wageComponent;
  final double? materialComponent;
  final DateTime lastCalculated;
  final String source;

  const RegionalCostFactor({
    required this.id,
    required this.state,
    this.metroArea,
    this.trade,
    this.multiplier = 1.0,
    this.wageComponent,
    this.materialComponent,
    required this.lastCalculated,
    this.source = 'bls',
  });

  factory RegionalCostFactor.fromJson(Map<String, dynamic> json) {
    return RegionalCostFactor(
      id: json['id'] as String,
      state: json['state'] as String,
      metroArea: json['metro_area'] as String?,
      trade: json['trade'] as String?,
      multiplier: _parseDouble(json['multiplier']) ?? 1.0,
      wageComponent: _parseDouble(json['wage_component']),
      materialComponent: _parseDouble(json['material_component']),
      lastCalculated: DateTime.parse(json['last_calculated'] as String),
      source: json['source'] as String? ?? 'bls',
    );
  }

  @override
  List<Object?> get props => [id, state, metroArea, trade];
}

// ════════════════════════════════════════════════════════════════
// DISTRIBUTOR ACCOUNT
// ════════════════════════════════════════════════════════════════

class DistributorAccount extends Equatable {
  final String id;
  final String companyId;
  final String supplierId;
  final String? accountNumber;
  final ConnectionStatus connectionStatus;
  final DateTime? lastSyncAt;
  final String? syncError;
  final bool useAccountPricing;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DistributorAccount({
    required this.id,
    required this.companyId,
    required this.supplierId,
    this.accountNumber,
    this.connectionStatus = ConnectionStatus.pending,
    this.lastSyncAt,
    this.syncError,
    this.useAccountPricing = true,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isConnected => connectionStatus == ConnectionStatus.connected;
  bool get hasError => connectionStatus == ConnectionStatus.error;

  factory DistributorAccount.fromJson(Map<String, dynamic> json) {
    return DistributorAccount(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      supplierId: json['supplier_id'] as String,
      accountNumber: json['account_number'] as String?,
      connectionStatus: ConnectionStatus.fromString(json['connection_status'] as String?),
      lastSyncAt: json['last_sync_at'] != null
          ? DateTime.parse(json['last_sync_at'] as String)
          : null,
      syncError: json['sync_error'] as String?,
      useAccountPricing: json['use_account_pricing'] as bool? ?? true,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'company_id': companyId,
    'supplier_id': supplierId,
    'account_number': accountNumber,
    'connection_status': connectionStatus.toJson(),
    'use_account_pricing': useAccountPricing,
    'created_by': createdBy,
  };

  @override
  List<Object?> get props => [id, companyId, supplierId, connectionStatus, updatedAt];
}

// ════════════════════════════════════════════════════════════════
// PRICE ALERT
// ════════════════════════════════════════════════════════════════

class PriceAlert extends Equatable {
  final String id;
  final String companyId;
  final String userId;
  final String productQuery;
  final String? productName;
  final String? materialCategory;
  final double? targetPrice;
  final double? currentPrice;
  final AlertType alertType;
  final double? dropPctThreshold;
  final bool isActive;
  final DateTime? triggeredAt;
  final DateTime? notifiedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PriceAlert({
    required this.id,
    required this.companyId,
    required this.userId,
    required this.productQuery,
    this.productName,
    this.materialCategory,
    this.targetPrice,
    this.currentPrice,
    this.alertType = AlertType.belowPrice,
    this.dropPctThreshold,
    this.isActive = true,
    this.triggeredAt,
    this.notifiedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isTriggered => triggeredAt != null;
  bool get isNotified => notifiedAt != null;

  factory PriceAlert.fromJson(Map<String, dynamic> json) {
    return PriceAlert(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      userId: json['user_id'] as String,
      productQuery: json['product_query'] as String,
      productName: json['product_name'] as String?,
      materialCategory: json['material_category'] as String?,
      targetPrice: _parseDouble(json['target_price']),
      currentPrice: _parseDouble(json['current_price']),
      alertType: AlertType.fromString(json['alert_type'] as String?),
      dropPctThreshold: _parseDouble(json['drop_pct_threshold']),
      isActive: json['is_active'] as bool? ?? true,
      triggeredAt: json['triggered_at'] != null
          ? DateTime.parse(json['triggered_at'] as String)
          : null,
      notifiedAt: json['notified_at'] != null
          ? DateTime.parse(json['notified_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'company_id': companyId,
    'user_id': userId,
    'product_query': productQuery,
    'product_name': productName,
    'material_category': materialCategory,
    'target_price': targetPrice,
    'current_price': currentPrice,
    'alert_type': alertType.toJson(),
    'drop_pct_threshold': dropPctThreshold,
    'is_active': isActive,
  };

  @override
  List<Object?> get props => [id, companyId, productQuery, alertType, updatedAt];
}

// ════════════════════════════════════════════════════════════════
// PRICING CONTRIBUTOR STATUS
// ════════════════════════════════════════════════════════════════

class PricingContributorStatus extends Equatable {
  final String id;
  final String companyId;
  final bool isContributor;
  final DateTime? optedOutAt;
  final int receiptCount;
  final int itemsContributed;
  final ContributorBadge badgeLevel;
  final DateTime? lastContributionAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PricingContributorStatus({
    required this.id,
    required this.companyId,
    this.isContributor = true,
    this.optedOutAt,
    this.receiptCount = 0,
    this.itemsContributed = 0,
    this.badgeLevel = ContributorBadge.none,
    this.lastContributionAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PricingContributorStatus.fromJson(Map<String, dynamic> json) {
    return PricingContributorStatus(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      isContributor: json['is_contributor'] as bool? ?? true,
      optedOutAt: json['opted_out_at'] != null
          ? DateTime.parse(json['opted_out_at'] as String)
          : null,
      receiptCount: (json['receipt_count'] as num?)?.toInt() ?? 0,
      itemsContributed: (json['items_contributed'] as num?)?.toInt() ?? 0,
      badgeLevel: ContributorBadge.fromString(json['badge_level'] as String?),
      lastContributionAt: json['last_contribution_at'] != null
          ? DateTime.parse(json['last_contribution_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'company_id': companyId,
    'is_contributor': isContributor,
    'opted_out_at': optedOutAt?.toUtc().toIso8601String(),
  };

  @override
  List<Object?> get props => [id, companyId, isContributor, badgeLevel, updatedAt];
}

// ════════════════════════════════════════════════════════════════
// HELPERS
// ════════════════════════════════════════════════════════════════

double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

List<String> _parseStringList(dynamic value) {
  if (value == null) return [];
  if (value is List) return value.map((e) => e.toString()).toList();
  return [];
}
