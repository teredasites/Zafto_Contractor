// ZAFTO Material Finder Repository
// Created: DEPTH32 — Product search, affiliate tracking, favorites, views
//
// Tables: supplier_products, affiliate_clicks, product_favorites, product_views

import '../core/supabase_client.dart';
import '../models/material_finder.dart';

class MaterialFinderRepository {
  static const _products = 'supplier_products';
  static const _clicks = 'affiliate_clicks';
  static const _favorites = 'product_favorites';
  static const _views = 'product_views';

  // ══════════════════════════════════════════════════════════════
  // SUPPLIER PRODUCTS — search & browse (read-only from app)
  // ══════════════════════════════════════════════════════════════

  /// Full-text search for products
  Future<List<SupplierProduct>> searchProducts({
    required String query,
    String? trade,
    String? materialCategory,
    String? supplierId,
    double? minPrice,
    double? maxPrice,
    bool? inStockOnly,
    String orderBy = 'rating',
    bool ascending = false,
    int limit = 30,
    int offset = 0,
  }) async {
    var q = supabase
        .from(_products)
        .select()
        .isFilter('deleted_at', null)
        .textSearch('name', query);

    if (trade != null) q = q.eq('trade', trade);
    if (materialCategory != null) {
      q = q.eq('material_category', materialCategory);
    }
    if (supplierId != null) q = q.eq('supplier_id', supplierId);
    if (minPrice != null) q = q.gte('price', minPrice);
    if (maxPrice != null) q = q.lte('price', maxPrice);
    if (inStockOnly == true) q = q.eq('in_stock', true);

    final data = await q
        .order(orderBy, ascending: ascending)
        .range(offset, offset + limit - 1);
    return data.map((row) => SupplierProduct.fromJson(row)).toList();
  }

  /// Browse products by trade/category (no text query)
  Future<List<SupplierProduct>> browseProducts({
    String? trade,
    String? materialCategory,
    String? supplierId,
    String? brand,
    bool? inStockOnly,
    String orderBy = 'name',
    bool ascending = true,
    int limit = 50,
    int offset = 0,
  }) async {
    var q = supabase.from(_products).select().isFilter('deleted_at', null);

    if (trade != null) q = q.eq('trade', trade);
    if (materialCategory != null) {
      q = q.eq('material_category', materialCategory);
    }
    if (supplierId != null) q = q.eq('supplier_id', supplierId);
    if (brand != null) q = q.eq('brand', brand);
    if (inStockOnly == true) q = q.eq('in_stock', true);

    final data = await q
        .order(orderBy, ascending: ascending)
        .range(offset, offset + limit - 1);
    return data.map((row) => SupplierProduct.fromJson(row)).toList();
  }

  /// Get single product by ID
  Future<SupplierProduct> getProduct(String id) async {
    final data = await supabase
        .from(_products)
        .select()
        .eq('id', id)
        .isFilter('deleted_at', null)
        .single();
    return SupplierProduct.fromJson(data);
  }

  /// Get products by UPC barcode
  Future<List<SupplierProduct>> getProductsByUpc(String upc) async {
    final data = await supabase
        .from(_products)
        .select()
        .eq('upc', upc)
        .isFilter('deleted_at', null);
    return data.map((row) => SupplierProduct.fromJson(row)).toList();
  }

  /// Get products on sale
  Future<List<SupplierProduct>> getSaleProducts({
    String? trade,
    int limit = 30,
  }) async {
    var q = supabase
        .from(_products)
        .select()
        .isFilter('deleted_at', null)
        .not('sale_price', 'is', null)
        .gte('sale_end_date', DateTime.now().toIso8601String());

    if (trade != null) q = q.eq('trade', trade);

    final data = await q
        .order('sale_end_date', ascending: true)
        .limit(limit);
    return data.map((row) => SupplierProduct.fromJson(row)).toList();
  }

  /// Compare prices across suppliers for similar products
  Future<List<SupplierProduct>> compareProductPrices(String productName) async {
    final data = await supabase
        .from(_products)
        .select()
        .isFilter('deleted_at', null)
        .ilike('name', '%$productName%')
        .not('price', 'is', null)
        .order('price', ascending: true)
        .limit(20);
    return data.map((row) => SupplierProduct.fromJson(row)).toList();
  }

  // ══════════════════════════════════════════════════════════════
  // AFFILIATE CLICKS — tracking outbound clicks
  // ══════════════════════════════════════════════════════════════

  /// Record an affiliate click
  Future<AffiliateClick> recordClick(AffiliateClick click) async {
    final data = await supabase
        .from(_clicks)
        .insert(click.toJson())
        .select()
        .single();
    return AffiliateClick.fromJson(data);
  }

  /// Get click history for the company
  Future<List<AffiliateClick>> getClickHistory({
    int limit = 50,
    int offset = 0,
  }) async {
    final data = await supabase
        .from(_clicks)
        .select()
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    return data.map((row) => AffiliateClick.fromJson(row)).toList();
  }

  // ══════════════════════════════════════════════════════════════
  // PRODUCT FAVORITES — save products for later
  // ══════════════════════════════════════════════════════════════

  /// Get user's favorited products
  Future<List<ProductFavorite>> getFavorites() async {
    final data = await supabase
        .from(_favorites)
        .select()
        .order('created_at', ascending: false);
    return data.map((row) => ProductFavorite.fromJson(row)).toList();
  }

  /// Add a product to favorites
  Future<ProductFavorite> addFavorite(ProductFavorite fav) async {
    final data = await supabase
        .from(_favorites)
        .upsert(fav.toJson(), onConflict: 'user_id,product_id')
        .select()
        .single();
    return ProductFavorite.fromJson(data);
  }

  /// Remove a product from favorites (physical delete — junction table)
  Future<void> removeFavorite(String id) async {
    await supabase.from(_favorites).delete().eq('id', id);
  }

  /// Check if a product is favorited
  Future<bool> isFavorited(String productId) async {
    final data = await supabase
        .from(_favorites)
        .select('id')
        .eq('product_id', productId)
        .maybeSingle();
    return data != null;
  }

  // ══════════════════════════════════════════════════════════════
  // PRODUCT VIEWS — recently viewed products
  // ══════════════════════════════════════════════════════════════

  /// Record a product view
  Future<void> recordView(ProductView view) async {
    await supabase.from(_views).insert(view.toJson());
  }

  /// Get recently viewed products
  Future<List<ProductView>> getRecentlyViewed({
    int limit = 20,
  }) async {
    final data = await supabase
        .from(_views)
        .select()
        .order('viewed_at', ascending: false)
        .limit(limit);
    return data.map((row) => ProductView.fromJson(row)).toList();
  }
}
