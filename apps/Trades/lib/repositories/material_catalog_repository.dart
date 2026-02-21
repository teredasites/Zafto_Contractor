// ZAFTO Material Catalog Repository — Supabase Backend
// Created: DEPTH29 — Estimate Engine Overhaul
//
// CRUD for material_catalog with tier-based filtering and supplier URLs.

import '../core/supabase_client.dart';
import '../core/errors.dart';
import '../models/material_catalog.dart';

class MaterialCatalogRepository {
  static const _table = 'material_catalog';

  /// Fetch all active materials, optionally filtered by trade
  Future<List<MaterialCatalogItem>> getMaterials({String? trade}) async {
    try {
      var query = supabase
          .from(_table)
          .select()
          .is_('deleted_at', null)
          .eq('is_disabled', false)
          .order('trade')
          .order('category')
          .order('tier')
          .order('name');

      if (trade != null) {
        query = supabase
            .from(_table)
            .select()
            .is_('deleted_at', null)
            .eq('is_disabled', false)
            .eq('trade', trade)
            .order('trade')
            .order('category')
            .order('tier')
            .order('name');
      }

      final response = await query;
      return (response as List)
          .map((row) => MaterialCatalogItem.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load material catalog',
        userMessage: 'Could not load materials.',
        cause: e,
      );
    }
  }

  /// Get a single material by ID
  Future<MaterialCatalogItem> getMaterial(String id) async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .eq('id', id)
          .single();

      return MaterialCatalogItem.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to load material $id',
        userMessage: 'Could not load material details.',
        cause: e,
      );
    }
  }

  /// Get materials by tier within a trade
  Future<List<MaterialCatalogItem>> getMaterialsByTier(
      MaterialTier tier, {String? trade}) async {
    try {
      var query = supabase
          .from(_table)
          .select()
          .is_('deleted_at', null)
          .eq('is_disabled', false)
          .eq('tier', materialTierToString(tier))
          .order('trade')
          .order('category')
          .order('name');

      if (trade != null) {
        query = supabase
            .from(_table)
            .select()
            .is_('deleted_at', null)
            .eq('is_disabled', false)
            .eq('tier', materialTierToString(tier))
            .eq('trade', trade)
            .order('trade')
            .order('category')
            .order('name');
      }

      final response = await query;
      return (response as List)
          .map((row) => MaterialCatalogItem.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load materials by tier',
        userMessage: 'Could not load materials for this tier.',
        cause: e,
      );
    }
  }

  /// Get tier equivalents for a specific material (same trade+category, different tiers)
  Future<List<MaterialCatalogItem>> getTierEquivalents(String materialId) async {
    try {
      final material = await getMaterial(materialId);
      final response = await supabase
          .from(_table)
          .select()
          .is_('deleted_at', null)
          .eq('is_disabled', false)
          .eq('trade', material.trade)
          .eq('category', material.category)
          .neq('id', materialId)
          .order('tier')
          .order('name');

      return (response as List)
          .map((row) => MaterialCatalogItem.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load tier equivalents',
        userMessage: 'Could not load alternative tiers.',
        cause: e,
      );
    }
  }

  /// Add a company-specific material
  Future<MaterialCatalogItem> addMaterial(Map<String, dynamic> data) async {
    try {
      final response = await supabase
          .from(_table)
          .insert(data)
          .select()
          .single();

      return MaterialCatalogItem.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to add material',
        userMessage: 'Could not add material. Please try again.',
        cause: e,
      );
    }
  }

  /// Update a material
  Future<MaterialCatalogItem> updateMaterial(
      String id, Map<String, dynamic> updates) async {
    try {
      final response = await supabase
          .from(_table)
          .update(updates)
          .eq('id', id)
          .select()
          .single();

      return MaterialCatalogItem.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to update material',
        userMessage: 'Could not update material. Please try again.',
        cause: e,
      );
    }
  }

  /// Soft delete a material
  Future<void> deleteMaterial(String id) async {
    try {
      await supabase
          .from(_table)
          .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', id);
    } catch (e) {
      throw DatabaseError(
        'Failed to delete material',
        userMessage: 'Could not remove material.',
        cause: e,
      );
    }
  }

  /// Toggle favorite status
  Future<void> toggleFavorite(String id, bool isFavorite) async {
    try {
      await supabase
          .from(_table)
          .update({'is_favorite': isFavorite})
          .eq('id', id);
    } catch (e) {
      throw DatabaseError(
        'Failed to toggle favorite',
        userMessage: 'Could not update favorite status.',
        cause: e,
      );
    }
  }
}
