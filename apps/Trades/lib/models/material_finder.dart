// ZAFTO Material Finder Models
// Created: DEPTH32 — Supplier Product Catalog, Affiliate Tracking,
// Product Favorites, Recently Viewed Products
//
// Tables: supplier_products, affiliate_clicks, product_favorites, product_views

import 'package:equatable/equatable.dart';

// ════════════════════════════════════════════════════════════════
// ENUMS
// ════════════════════════════════════════════════════════════════

enum AffiliateNetwork {
  impactRadius,
  cjAffiliate,
  amazon,
  direct,
  none;

  String toJson() {
    switch (this) {
      case AffiliateNetwork.impactRadius:
        return 'impact_radius';
      case AffiliateNetwork.cjAffiliate:
        return 'cj_affiliate';
      case AffiliateNetwork.amazon:
        return 'amazon';
      case AffiliateNetwork.direct:
        return 'direct';
      case AffiliateNetwork.none:
        return 'none';
    }
  }

  static AffiliateNetwork fromJson(String? value) {
    switch (value) {
      case 'impact_radius':
        return AffiliateNetwork.impactRadius;
      case 'cj_affiliate':
        return AffiliateNetwork.cjAffiliate;
      case 'amazon':
        return AffiliateNetwork.amazon;
      case 'direct':
        return AffiliateNetwork.direct;
      default:
        return AffiliateNetwork.none;
    }
  }
}

// ════════════════════════════════════════════════════════════════
// SUPPLIER PRODUCT (system-wide catalog — no company_id)
// ════════════════════════════════════════════════════════════════

class SupplierProduct extends Equatable {
  final String id;
  final String supplierId;
  final String? externalProductId;
  final String name;
  final String? description;
  final String? brand;
  final String? modelNumber;
  final String? sku;
  final String? upc;
  final String? categoryPath;
  final String? trade;
  final String? materialCategory;
  final double? price;
  final double? salePrice;
  final String? saleEndDate;
  final bool inStock;
  final String? imageUrl;
  final String? productUrl;
  final AffiliateNetwork? affiliateNetwork;
  final double? commissionRate;
  final String? lastFeedUpdate;
  final List<Map<String, dynamic>> priceHistory;
  final Map<String, dynamic> specs;
  final double? rating;
  final int reviewCount;
  final String createdAt;
  final String updatedAt;

  const SupplierProduct({
    required this.id,
    required this.supplierId,
    this.externalProductId,
    required this.name,
    this.description,
    this.brand,
    this.modelNumber,
    this.sku,
    this.upc,
    this.categoryPath,
    this.trade,
    this.materialCategory,
    this.price,
    this.salePrice,
    this.saleEndDate,
    this.inStock = true,
    this.imageUrl,
    this.productUrl,
    this.affiliateNetwork,
    this.commissionRate,
    this.lastFeedUpdate,
    this.priceHistory = const [],
    this.specs = const {},
    this.rating,
    this.reviewCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SupplierProduct.fromJson(Map<String, dynamic> json) {
    return SupplierProduct(
      id: json['id'] as String,
      supplierId: json['supplier_id'] as String,
      externalProductId: json['external_product_id'] as String?,
      name: json['name'] as String,
      description: json['description'] as String?,
      brand: json['brand'] as String?,
      modelNumber: json['model_number'] as String?,
      sku: json['sku'] as String?,
      upc: json['upc'] as String?,
      categoryPath: json['category_path'] as String?,
      trade: json['trade'] as String?,
      materialCategory: json['material_category'] as String?,
      price: _parseDouble(json['price']),
      salePrice: _parseDouble(json['sale_price']),
      saleEndDate: json['sale_end_date'] as String?,
      inStock: json['in_stock'] as bool? ?? true,
      imageUrl: json['image_url'] as String?,
      productUrl: json['product_url'] as String?,
      affiliateNetwork: json['affiliate_network'] != null
          ? AffiliateNetwork.fromJson(json['affiliate_network'] as String)
          : null,
      commissionRate: _parseDouble(json['commission_rate']),
      lastFeedUpdate: json['last_feed_update'] as String?,
      priceHistory: (json['price_history'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          const [],
      specs: json['specs'] != null
          ? Map<String, dynamic>.from(json['specs'] as Map)
          : const {},
      rating: _parseDouble(json['rating']),
      reviewCount: json['review_count'] as int? ?? 0,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }

  /// Whether the product is currently on sale
  bool get isOnSale =>
      salePrice != null &&
      price != null &&
      salePrice! < price! &&
      (saleEndDate == null ||
          DateTime.tryParse(saleEndDate!)?.isAfter(DateTime.now()) == true);

  /// Savings amount if on sale
  double? get savingsAmount =>
      isOnSale ? (price! - salePrice!) : null;

  /// Savings percentage if on sale
  double? get savingsPct =>
      isOnSale && price! > 0 ? ((price! - salePrice!) / price! * 100) : null;

  /// The effective price (sale or regular)
  double? get effectivePrice => isOnSale ? salePrice : price;

  /// Whether the product has affiliate tracking
  bool get hasAffiliate =>
      affiliateNetwork != null && affiliateNetwork != AffiliateNetwork.none;

  @override
  List<Object?> get props => [id, supplierId, name, price, salePrice, updatedAt];
}

// ════════════════════════════════════════════════════════════════
// AFFILIATE CLICK (company-scoped — revenue tracking)
// ════════════════════════════════════════════════════════════════

class AffiliateClick extends Equatable {
  final String id;
  final String companyId;
  final String userId;
  final String? productId;
  final String? supplierId;
  final String? productName;
  final String? supplierName;
  final double? priceAtClick;
  final String? affiliateNetwork;
  final String? clickUrl;
  final bool converted;
  final double? conversionAmount;
  final double? commissionEarned;
  final String createdAt;

  const AffiliateClick({
    required this.id,
    required this.companyId,
    required this.userId,
    this.productId,
    this.supplierId,
    this.productName,
    this.supplierName,
    this.priceAtClick,
    this.affiliateNetwork,
    this.clickUrl,
    this.converted = false,
    this.conversionAmount,
    this.commissionEarned,
    required this.createdAt,
  });

  factory AffiliateClick.fromJson(Map<String, dynamic> json) {
    return AffiliateClick(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      userId: json['user_id'] as String,
      productId: json['product_id'] as String?,
      supplierId: json['supplier_id'] as String?,
      productName: json['product_name'] as String?,
      supplierName: json['supplier_name'] as String?,
      priceAtClick: _parseDouble(json['price_at_click']),
      affiliateNetwork: json['affiliate_network'] as String?,
      clickUrl: json['click_url'] as String?,
      converted: json['converted'] as bool? ?? false,
      conversionAmount: _parseDouble(json['conversion_amount']),
      commissionEarned: _parseDouble(json['commission_earned']),
      createdAt: json['created_at'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'company_id': companyId,
        'user_id': userId,
        'product_id': productId,
        'supplier_id': supplierId,
        'product_name': productName,
        'supplier_name': supplierName,
        'price_at_click': priceAtClick,
        'affiliate_network': affiliateNetwork,
        'click_url': clickUrl,
      };

  @override
  List<Object?> get props => [id, companyId, productId, createdAt];
}

// ════════════════════════════════════════════════════════════════
// PRODUCT FAVORITE (company-scoped, UNIQUE user_id + product_id)
// ════════════════════════════════════════════════════════════════

class ProductFavorite extends Equatable {
  final String id;
  final String companyId;
  final String userId;
  final String productId;
  final String? notes;
  final String createdAt;

  const ProductFavorite({
    required this.id,
    required this.companyId,
    required this.userId,
    required this.productId,
    this.notes,
    required this.createdAt,
  });

  factory ProductFavorite.fromJson(Map<String, dynamic> json) {
    return ProductFavorite(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      userId: json['user_id'] as String,
      productId: json['product_id'] as String,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'company_id': companyId,
        'user_id': userId,
        'product_id': productId,
        'notes': notes,
      };

  @override
  List<Object?> get props => [id, userId, productId];
}

// ════════════════════════════════════════════════════════════════
// PRODUCT VIEW (company-scoped — recently viewed tracking)
// ════════════════════════════════════════════════════════════════

class ProductView extends Equatable {
  final String id;
  final String companyId;
  final String userId;
  final String productId;
  final String viewedAt;

  const ProductView({
    required this.id,
    required this.companyId,
    required this.userId,
    required this.productId,
    required this.viewedAt,
  });

  factory ProductView.fromJson(Map<String, dynamic> json) {
    return ProductView(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      userId: json['user_id'] as String,
      productId: json['product_id'] as String,
      viewedAt: json['viewed_at'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'company_id': companyId,
        'user_id': userId,
        'product_id': productId,
      };

  @override
  List<Object?> get props => [id, userId, productId, viewedAt];
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
