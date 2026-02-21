// ZAFTO Material Finder Providers
// Created: DEPTH32 — Product search, affiliate tracking, favorites, views
//
// Riverpod providers for supplier products, affiliate clicks,
// product favorites, and recently viewed products.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/material_finder.dart';
import '../repositories/material_finder_repository.dart';

// ════════════════════════════════════════════════════════════════
// REPOSITORY
// ════════════════════════════════════════════════════════════════

final materialFinderRepoProvider =
    Provider<MaterialFinderRepository>((ref) {
  return MaterialFinderRepository();
});

// ════════════════════════════════════════════════════════════════
// SUPPLIER PRODUCTS — SEARCH & BROWSE
// ════════════════════════════════════════════════════════════════

/// Search products by text query
final productSearchProvider = FutureProvider.autoDispose
    .family<List<SupplierProduct>, String>((ref, query) async {
  final repo = ref.read(materialFinderRepoProvider);
  return repo.searchProducts(query: query);
});

/// Browse products by trade
final productsByTradeProvider = FutureProvider.autoDispose
    .family<List<SupplierProduct>, String>((ref, trade) async {
  final repo = ref.read(materialFinderRepoProvider);
  return repo.browseProducts(trade: trade);
});

/// Browse products by supplier
final productsBySupplierProvider = FutureProvider.autoDispose
    .family<List<SupplierProduct>, String>((ref, supplierId) async {
  final repo = ref.read(materialFinderRepoProvider);
  return repo.browseProducts(supplierId: supplierId);
});

/// Single product by ID
final productDetailProvider = FutureProvider.autoDispose
    .family<SupplierProduct, String>((ref, id) async {
  final repo = ref.read(materialFinderRepoProvider);
  return repo.getProduct(id);
});

/// Products by UPC barcode
final productsByUpcProvider = FutureProvider.autoDispose
    .family<List<SupplierProduct>, String>((ref, upc) async {
  final repo = ref.read(materialFinderRepoProvider);
  return repo.getProductsByUpc(upc);
});

/// Products currently on sale
final saleProductsProvider = FutureProvider.autoDispose
    .family<List<SupplierProduct>, String?>((ref, trade) async {
  final repo = ref.read(materialFinderRepoProvider);
  return repo.getSaleProducts(trade: trade);
});

/// Price comparison for a product name
final priceComparisonProvider = FutureProvider.autoDispose
    .family<List<SupplierProduct>, String>((ref, productName) async {
  final repo = ref.read(materialFinderRepoProvider);
  return repo.compareProductPrices(productName);
});

// ════════════════════════════════════════════════════════════════
// AFFILIATE CLICKS
// ════════════════════════════════════════════════════════════════

/// Click history
final affiliateClickHistoryProvider =
    FutureProvider.autoDispose<List<AffiliateClick>>((ref) async {
  final repo = ref.read(materialFinderRepoProvider);
  return repo.getClickHistory();
});

// ════════════════════════════════════════════════════════════════
// PRODUCT FAVORITES
// ════════════════════════════════════════════════════════════════

/// All favorites
final productFavoritesProvider =
    FutureProvider.autoDispose<List<ProductFavorite>>((ref) async {
  final repo = ref.read(materialFinderRepoProvider);
  return repo.getFavorites();
});

/// Check if product is favorited
final isProductFavoritedProvider = FutureProvider.autoDispose
    .family<bool, String>((ref, productId) async {
  final repo = ref.read(materialFinderRepoProvider);
  return repo.isFavorited(productId);
});

// ════════════════════════════════════════════════════════════════
// RECENTLY VIEWED
// ════════════════════════════════════════════════════════════════

/// Recently viewed products
final recentlyViewedProductsProvider =
    FutureProvider.autoDispose<List<ProductView>>((ref) async {
  final repo = ref.read(materialFinderRepoProvider);
  return repo.getRecentlyViewed();
});
