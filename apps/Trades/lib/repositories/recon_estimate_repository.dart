// ZAFTO Recon-to-Estimate Pipeline Repository — Supabase Backend
// Created: DEPTH30 — One Address → Complete Bid
//
// CRUD for recon_estimate_mappings, recon_material_recommendations,
// estimate_bundles, and cross_trade_dependencies tables.

import '../core/supabase_client.dart';
import '../core/errors.dart';
import '../models/recon_estimate_pipeline.dart';

class ReconEstimateRepository {
  static const _mappingsTable = 'recon_estimate_mappings';
  static const _recommendationsTable = 'recon_material_recommendations';
  static const _bundlesTable = 'estimate_bundles';
  static const _dependenciesTable = 'cross_trade_dependencies';

  // ==================== MEASUREMENT MAPPINGS ====================

  /// Get all active mappings for a trade (system defaults + company overrides)
  Future<List<ReconEstimateMapping>> getMappings(String trade) async {
    try {
      final response = await supabase
          .from(_mappingsTable)
          .select()
          .eq('trade', trade)
          .eq('is_active', true)
          .isFilter('deleted_at', null)
          .order('sort_order');

      return (response as List)
          .map((row) => ReconEstimateMapping.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load recon-estimate mappings',
        userMessage: 'Could not load estimate mapping rules.',
        cause: e,
      );
    }
  }

  /// Get all mappings (all trades) for admin/settings
  Future<List<ReconEstimateMapping>> getAllMappings() async {
    try {
      final response = await supabase
          .from(_mappingsTable)
          .select()
          .isFilter('deleted_at', null)
          .order('trade')
          .order('sort_order');

      return (response as List)
          .map((row) => ReconEstimateMapping.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load all mappings',
        userMessage: 'Could not load mapping rules.',
        cause: e,
      );
    }
  }

  /// Add a company-specific mapping override
  Future<ReconEstimateMapping> addMapping(Map<String, dynamic> data) async {
    try {
      final response = await supabase
          .from(_mappingsTable)
          .insert(data)
          .select()
          .single();

      return ReconEstimateMapping.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to add mapping',
        userMessage: 'Could not add mapping rule. Please try again.',
        cause: e,
      );
    }
  }

  /// Update a mapping
  Future<ReconEstimateMapping> updateMapping(
      String id, Map<String, dynamic> updates) async {
    try {
      final response = await supabase
          .from(_mappingsTable)
          .update(updates)
          .eq('id', id)
          .select()
          .single();

      return ReconEstimateMapping.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to update mapping',
        userMessage: 'Could not update mapping rule. Please try again.',
        cause: e,
      );
    }
  }

  /// Soft delete a mapping
  Future<void> deleteMapping(String id) async {
    try {
      await supabase
          .from(_mappingsTable)
          .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', id);
    } catch (e) {
      throw DatabaseError(
        'Failed to delete mapping',
        userMessage: 'Could not remove mapping rule.',
        cause: e,
      );
    }
  }

  // ==================== MATERIAL RECOMMENDATIONS ====================

  /// Get recommendations for a trade (system + company-specific)
  Future<List<ReconMaterialRecommendation>> getRecommendations(
      String trade) async {
    try {
      final response = await supabase
          .from(_recommendationsTable)
          .select()
          .or('trade.eq.$trade,trade.eq.general')
          .eq('is_active', true)
          .isFilter('deleted_at', null)
          .order('sort_order');

      return (response as List)
          .map((row) => ReconMaterialRecommendation.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load material recommendations',
        userMessage: 'Could not load material recommendations.',
        cause: e,
      );
    }
  }

  /// Get all recommendations (all trades)
  Future<List<ReconMaterialRecommendation>> getAllRecommendations() async {
    try {
      final response = await supabase
          .from(_recommendationsTable)
          .select()
          .isFilter('deleted_at', null)
          .order('trade')
          .order('sort_order');

      return (response as List)
          .map((row) => ReconMaterialRecommendation.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load all recommendations',
        userMessage: 'Could not load recommendations.',
        cause: e,
      );
    }
  }

  // ==================== ESTIMATE BUNDLES ====================

  /// Get all bundles for the company
  Future<List<EstimateBundle>> getBundles() async {
    try {
      final response = await supabase
          .from(_bundlesTable)
          .select()
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false);

      return (response as List)
          .map((row) => EstimateBundle.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load estimate bundles',
        userMessage: 'Could not load bundled estimates.',
        cause: e,
      );
    }
  }

  /// Get a single bundle
  Future<EstimateBundle> getBundle(String id) async {
    try {
      final response = await supabase
          .from(_bundlesTable)
          .select()
          .eq('id', id)
          .single();

      return EstimateBundle.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to load bundle',
        userMessage: 'Could not load bundled estimate.',
        cause: e,
      );
    }
  }

  /// Create a new bundle
  Future<EstimateBundle> createBundle(Map<String, dynamic> data) async {
    try {
      final response = await supabase
          .from(_bundlesTable)
          .insert(data)
          .select()
          .single();

      return EstimateBundle.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to create bundle',
        userMessage: 'Could not create estimate bundle. Please try again.',
        cause: e,
      );
    }
  }

  /// Update a bundle
  Future<EstimateBundle> updateBundle(
      String id, Map<String, dynamic> updates) async {
    try {
      final response = await supabase
          .from(_bundlesTable)
          .update(updates)
          .eq('id', id)
          .select()
          .single();

      return EstimateBundle.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to update bundle',
        userMessage: 'Could not update estimate bundle. Please try again.',
        cause: e,
      );
    }
  }

  /// Soft delete a bundle
  Future<void> deleteBundle(String id) async {
    try {
      await supabase
          .from(_bundlesTable)
          .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', id);
    } catch (e) {
      throw DatabaseError(
        'Failed to delete bundle',
        userMessage: 'Could not remove estimate bundle.',
        cause: e,
      );
    }
  }

  // ==================== CROSS-TRADE DEPENDENCIES ====================

  /// Get all cross-trade dependencies
  Future<List<CrossTradeDependency2>> getDependencies() async {
    try {
      final response = await supabase
          .from(_dependenciesTable)
          .select()
          .order('sort_order');

      return (response as List)
          .map((row) => CrossTradeDependency2.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load cross-trade dependencies',
        userMessage: 'Could not load trade dependency data.',
        cause: e,
      );
    }
  }

  /// Get dependencies relevant to specific trades
  Future<List<CrossTradeDependency2>> getDependenciesForTrades(
      List<String> trades) async {
    try {
      final tradeFilter = trades.map((t) => 'primary_trade.eq.$t,dependent_trade.eq.$t').join(',');
      final response = await supabase
          .from(_dependenciesTable)
          .select()
          .or(tradeFilter)
          .order('sort_order');

      return (response as List)
          .map((row) => CrossTradeDependency2.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load trade dependencies',
        userMessage: 'Could not load trade dependency warnings.',
        cause: e,
      );
    }
  }
}
