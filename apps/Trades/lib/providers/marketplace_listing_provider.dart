import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/marketplace_listing.dart';
import '../repositories/marketplace_listing_repository.dart';

/// Repository singleton.
final marketplaceListingRepoProvider =
    Provider<MarketplaceListingRepository>((ref) {
  return MarketplaceListingRepository(Supabase.instance.client);
});

/// All active marketplace sources.
final marketplaceSourcesProvider =
    FutureProvider.autoDispose<List<MarketplaceSource>>((ref) async {
  final repo = ref.watch(marketplaceListingRepoProvider);
  return repo.getSources();
});

/// Listings for a company with optional filters.
final marketplaceListingsProvider = FutureProvider.autoDispose.family<
    List<MarketplaceListing>,
    ({
      String companyId,
      String? tradeCategory,
      String? itemCategory,
      String? sourceId,
      String? status,
      String? brand,
      int? maxPriceCents,
    })>((ref, params) async {
  final repo = ref.watch(marketplaceListingRepoProvider);
  return repo.getListings(
    params.companyId,
    tradeCategory: params.tradeCategory,
    itemCategory: params.itemCategory,
    sourceId: params.sourceId,
    status: params.status,
    brand: params.brand,
    maxPriceCents: params.maxPriceCents,
  );
});

/// Single listing by ID.
final marketplaceListingByIdProvider =
    FutureProvider.autoDispose.family<MarketplaceListing?, String>(
        (ref, id) async {
  final repo = ref.watch(marketplaceListingRepoProvider);
  return repo.getById(id);
});

/// Search listings by text.
final marketplaceSearchResultsProvider = FutureProvider.autoDispose
    .family<List<MarketplaceListing>, ({String companyId, String query})>(
        (ref, params) async {
  final repo = ref.watch(marketplaceListingRepoProvider);
  return repo.search(params.companyId, params.query);
});

/// Saved listings for a user.
final marketplaceSavedListingsProvider = FutureProvider.autoDispose.family<
    List<MarketplaceSavedListing>,
    ({String companyId, String userId, String? savedType})>(
        (ref, params) async {
  final repo = ref.watch(marketplaceListingRepoProvider);
  return repo.getSavedListings(
    params.companyId,
    params.userId,
    savedType: params.savedType,
  );
});

/// Saved searches for a user.
final marketplaceSavedSearchesProvider = FutureProvider.autoDispose
    .family<List<MarketplaceSearch>, ({String companyId, String userId})>(
        (ref, params) async {
  final repo = ref.watch(marketplaceListingRepoProvider);
  return repo.getSavedSearches(params.companyId, params.userId);
});

/// CPSC recall search.
final cpscRecallSearchProvider = FutureProvider.autoDispose
    .family<List<CpscRecallRecord>, String>((ref, query) async {
  final repo = ref.watch(marketplaceListingRepoProvider);
  return repo.searchRecalls(query);
});
