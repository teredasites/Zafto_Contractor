import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/marketplace_listing.dart';

class MarketplaceListingRepository {
  final SupabaseClient _client;

  MarketplaceListingRepository(this._client);

  // ── Sources ──

  /// Get all active marketplace sources.
  Future<List<MarketplaceSource>> getSources() async {
    final res = await _client
        .from('marketplace_sources')
        .select()
        .eq('is_active', true)
        .order('name');

    return (res as List)
        .map((e) => MarketplaceSource.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Listings ──

  /// Get listings for a company with optional filters.
  Future<List<MarketplaceListing>> getListings(
    String companyId, {
    String? tradeCategory,
    String? itemCategory,
    String? sourceId,
    String? status,
    String? brand,
    int? maxPriceCents,
    int limit = 50,
    int offset = 0,
  }) async {
    var query = _client
        .from('marketplace_listings')
        .select()
        .eq('company_id', companyId)
        .isFilter('deleted_at', null);

    if (tradeCategory != null) {
      query = query.eq('trade_category', tradeCategory);
    }
    if (itemCategory != null) {
      query = query.eq('item_category', itemCategory);
    }
    if (sourceId != null) {
      query = query.eq('source_id', sourceId);
    }
    if (status != null) {
      query = query.eq('status', status);
    } else {
      query = query.eq('status', 'active');
    }
    if (brand != null) {
      query = query.ilike('brand', '%$brand%');
    }
    if (maxPriceCents != null) {
      query = query.lte('price_cents', maxPriceCents);
    }

    final res = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (res as List)
        .map((e) => MarketplaceListing.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get a single listing by ID.
  Future<MarketplaceListing?> getById(String id) async {
    final res = await _client
        .from('marketplace_listings')
        .select()
        .eq('id', id)
        .isFilter('deleted_at', null)
        .maybeSingle();

    if (res == null) return null;
    return MarketplaceListing.fromJson(res);
  }

  /// Search listings by text query.
  Future<List<MarketplaceListing>> search(
    String companyId,
    String query, {
    int limit = 30,
  }) async {
    final res = await _client
        .from('marketplace_listings')
        .select()
        .eq('company_id', companyId)
        .eq('status', 'active')
        .isFilter('deleted_at', null)
        .or('title.ilike.%$query%,description.ilike.%$query%,brand.ilike.%$query%')
        .order('created_at', ascending: false)
        .limit(limit);

    return (res as List)
        .map((e) => MarketplaceListing.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Create a new listing (manual import or paste-link).
  Future<MarketplaceListing> create(Map<String, dynamic> data) async {
    final res = await _client
        .from('marketplace_listings')
        .insert(data)
        .select()
        .single();
    return MarketplaceListing.fromJson(res);
  }

  /// Update a listing.
  Future<void> update(String id, Map<String, dynamic> data) async {
    await _client
        .from('marketplace_listings')
        .update(data)
        .eq('id', id);
  }

  /// Update listing status.
  Future<void> updateStatus(String id, String status) async {
    await _client
        .from('marketplace_listings')
        .update({'status': status})
        .eq('id', id);
  }

  /// Mark recall info on a listing.
  Future<void> markRecall(
    String id, {
    required bool found,
    String? recallId,
    String? recallDescription,
  }) async {
    await _client.from('marketplace_listings').update({
      'recall_checked': true,
      'recall_found': found,
      'recall_id': recallId,
      'recall_description': recallDescription,
    }).eq('id', id);
  }

  /// Soft delete a listing.
  Future<void> softDelete(String id) async {
    await _client.from('marketplace_listings').update({
      'deleted_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  // ── Saved Listings ──

  /// Get saved listings for a user.
  Future<List<MarketplaceSavedListing>> getSavedListings(
    String companyId,
    String userId, {
    String? savedType,
  }) async {
    var query = _client
        .from('marketplace_saved_listings')
        .select()
        .eq('company_id', companyId)
        .eq('user_id', userId);

    if (savedType != null) {
      query = query.eq('saved_type', savedType);
    }

    final res = await query.order('created_at', ascending: false);

    return (res as List)
        .map((e) =>
            MarketplaceSavedListing.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Save a listing (favorite/watch/compare).
  Future<MarketplaceSavedListing> saveListing(
      Map<String, dynamic> data) async {
    final res = await _client
        .from('marketplace_saved_listings')
        .insert(data)
        .select()
        .single();
    return MarketplaceSavedListing.fromJson(res);
  }

  /// Remove a saved listing.
  Future<void> unsaveListing(String id) async {
    await _client
        .from('marketplace_saved_listings')
        .delete()
        .eq('id', id);
  }

  // ── Saved Searches ──

  /// Get saved searches for a user.
  Future<List<MarketplaceSearch>> getSavedSearches(
    String companyId,
    String userId,
  ) async {
    final res = await _client
        .from('marketplace_searches')
        .select()
        .eq('company_id', companyId)
        .eq('user_id', userId)
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false);

    return (res as List)
        .map((e) => MarketplaceSearch.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Create a saved search.
  Future<MarketplaceSearch> createSearch(Map<String, dynamic> data) async {
    final res = await _client
        .from('marketplace_searches')
        .insert(data)
        .select()
        .single();
    return MarketplaceSearch.fromJson(res);
  }

  /// Update a saved search.
  Future<void> updateSearch(String id, Map<String, dynamic> data) async {
    await _client
        .from('marketplace_searches')
        .update(data)
        .eq('id', id);
  }

  /// Soft delete a saved search.
  Future<void> deleteSearch(String id) async {
    await _client.from('marketplace_searches').update({
      'deleted_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  // ── CPSC Recall Cache ──

  /// Search recall cache by product name or manufacturer.
  Future<List<CpscRecallRecord>> searchRecalls(String query) async {
    final res = await _client
        .from('cpsc_recall_cache')
        .select()
        .or('product_name.ilike.%$query%,manufacturer.ilike.%$query%')
        .order('recall_date', ascending: false)
        .limit(20);

    return (res as List)
        .map((e) => CpscRecallRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get a recall by recall number.
  Future<CpscRecallRecord?> getRecallByNumber(String recallNumber) async {
    final res = await _client
        .from('cpsc_recall_cache')
        .select()
        .eq('recall_number', recallNumber)
        .maybeSingle();

    if (res == null) return null;
    return CpscRecallRecord.fromJson(res);
  }
}
