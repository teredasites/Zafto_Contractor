// ZAFTO Price Book Repository — Supabase Backend
// Created: DEPTH29 — Estimate Engine Overhaul
//
// Company-specific known prices for one-click use in estimates/invoices.
// S130 Owner Directive implementation.

import '../core/supabase_client.dart';
import '../core/errors.dart';
import '../models/price_book_item.dart';

class PriceBookRepository {
  static const _table = 'price_book_items';

  /// Fetch all active price book items
  Future<List<PriceBookItem>> getItems() async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .isFilter('deleted_at', null)
          .eq('is_active', true)
          .order('category')
          .order('name');

      return (response as List)
          .map((row) => PriceBookItem.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load price book',
        userMessage: 'Could not load price book.',
        cause: e,
      );
    }
  }

  /// Get items filtered by trade
  Future<List<PriceBookItem>> getByTrade(String trade) async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .isFilter('deleted_at', null)
          .eq('is_active', true)
          .eq('trade', trade)
          .order('category')
          .order('name');

      return (response as List)
          .map((row) => PriceBookItem.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load price book by trade',
        userMessage: 'Could not load price book items for this trade.',
        cause: e,
      );
    }
  }

  /// Search price book items
  Future<List<PriceBookItem>> search(String query) async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .isFilter('deleted_at', null)
          .eq('is_active', true)
          .or('name.ilike.%$query%,sku.ilike.%$query%,description.ilike.%$query%,category.ilike.%$query%')
          .order('name')
          .limit(50);

      return (response as List)
          .map((row) => PriceBookItem.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to search price book',
        userMessage: 'Search failed. Please try again.',
        cause: e,
      );
    }
  }

  /// Add a price book item
  Future<PriceBookItem> addItem(Map<String, dynamic> data) async {
    try {
      final response = await supabase
          .from(_table)
          .insert(data)
          .select()
          .single();

      return PriceBookItem.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to add price book item',
        userMessage: 'Could not add item. Please try again.',
        cause: e,
      );
    }
  }

  /// Update a price book item
  Future<PriceBookItem> updateItem(
      String id, Map<String, dynamic> updates) async {
    try {
      final response = await supabase
          .from(_table)
          .update(updates)
          .eq('id', id)
          .select()
          .single();

      return PriceBookItem.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to update price book item',
        userMessage: 'Could not update item. Please try again.',
        cause: e,
      );
    }
  }

  /// Soft delete a price book item
  Future<void> deleteItem(String id) async {
    try {
      await supabase
          .from(_table)
          .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', id);
    } catch (e) {
      throw DatabaseError(
        'Failed to delete price book item',
        userMessage: 'Could not remove item.',
        cause: e,
      );
    }
  }
}
