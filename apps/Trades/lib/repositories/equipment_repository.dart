// ZAFTO Equipment Repository
// Created: Sprint FIELD2 (Session 131)
//
// CRUD for equipment_items + equipment_checkouts tables.
// Handles checkout/checkin flow with condition tracking.

import '../core/errors.dart';
import '../core/supabase_client.dart';
import '../models/equipment_item.dart';
import '../models/equipment_checkout.dart';

class EquipmentRepository {
  // ============================================================
  // EQUIPMENT ITEMS
  // ============================================================

  /// Get all equipment items for the company, with optional filters.
  Future<List<EquipmentItem>> getItems({
    EquipmentCategory? category,
    EquipmentCondition? condition,
    bool? checkedOut,
    String? search,
  }) async {
    try {
      var query = supabase
          .from('equipment_items')
          .select()
          .isFilter('deleted_at', null)
          .eq('is_active', true);

      if (category != null) {
        query = query.eq('category', category.dbValue);
      }
      if (condition != null) {
        query = query.eq('condition', condition.dbValue);
      }

      final response = await query.order('name');
      var items = (response as List)
          .map((row) => EquipmentItem.fromJson(row as Map<String, dynamic>))
          .toList();

      // Client-side filters for complex conditions
      if (checkedOut == true) {
        items = items.where((i) => i.isCheckedOut).toList();
      } else if (checkedOut == false) {
        items = items.where((i) => !i.isCheckedOut).toList();
      }

      if (search != null && search.isNotEmpty) {
        final q = search.toLowerCase();
        items = items.where((i) {
          return i.name.toLowerCase().contains(q) ||
              (i.serialNumber?.toLowerCase().contains(q) ?? false) ||
              (i.barcode?.toLowerCase().contains(q) ?? false) ||
              (i.manufacturer?.toLowerCase().contains(q) ?? false);
        }).toList();
      }

      return items;
    } catch (e) {
      if (e is AppError) rethrow;
      throw DatabaseError('Failed to fetch equipment items: $e', cause: e);
    }
  }

  /// Get a single equipment item by ID.
  Future<EquipmentItem> getItem(String itemId) async {
    try {
      final response = await supabase
          .from('equipment_items')
          .select()
          .eq('id', itemId)
          .single();

      return EquipmentItem.fromJson(response);
    } catch (e) {
      if (e is AppError) rethrow;
      throw DatabaseError('Failed to fetch equipment item: $e', cause: e);
    }
  }

  /// Find equipment by barcode (for QR/barcode scanning).
  Future<EquipmentItem?> findByBarcode(String barcode) async {
    try {
      final response = await supabase
          .from('equipment_items')
          .select()
          .eq('barcode', barcode)
          .isFilter('deleted_at', null)
          .maybeSingle();

      if (response == null) return null;
      return EquipmentItem.fromJson(response);
    } catch (e) {
      throw DatabaseError('Failed to find equipment by barcode: $e', cause: e);
    }
  }

  /// Create a new equipment item.
  Future<EquipmentItem> createItem({
    required String name,
    required EquipmentCategory category,
    String? serialNumber,
    String? barcode,
    String? manufacturer,
    String? modelNumber,
    DateTime? purchaseDate,
    double? purchaseCost,
    EquipmentCondition condition = EquipmentCondition.good,
    String? storageLocation,
    String? photoUrl,
    String? notes,
  }) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) throw AuthError('Not authenticated');
      final companyId = currentUser!.appMetadata['company_id'] as String?;
      if (companyId == null) throw AuthError('No company');

      final response = await supabase
          .from('equipment_items')
          .insert({
            'company_id': companyId,
            'name': name,
            'category': category.dbValue,
            'serial_number': serialNumber,
            'barcode': barcode,
            'manufacturer': manufacturer,
            'model_number': modelNumber,
            'purchase_date': purchaseDate?.toIso8601String().split('T').first,
            'purchase_cost': purchaseCost,
            'condition': condition.dbValue,
            'storage_location': storageLocation,
            'photo_url': photoUrl,
            'notes': notes,
          })
          .select()
          .single();

      return EquipmentItem.fromJson(response);
    } catch (e) {
      if (e is AppError) rethrow;
      throw DatabaseError('Failed to create equipment item: $e', cause: e);
    }
  }

  /// Update an equipment item.
  Future<EquipmentItem> updateItem(String itemId, Map<String, dynamic> updates) async {
    try {
      final response = await supabase
          .from('equipment_items')
          .update(updates)
          .eq('id', itemId)
          .select()
          .single();

      return EquipmentItem.fromJson(response);
    } catch (e) {
      if (e is AppError) rethrow;
      throw DatabaseError('Failed to update equipment item: $e', cause: e);
    }
  }

  /// Soft delete an equipment item.
  Future<void> deleteItem(String itemId) async {
    try {
      await supabase
          .from('equipment_items')
          .update({'deleted_at': DateTime.now().toUtc().toIso8601String(), 'is_active': false})
          .eq('id', itemId);
    } catch (e) {
      throw DatabaseError('Failed to delete equipment item: $e', cause: e);
    }
  }

  // ============================================================
  // CHECKOUTS
  // ============================================================

  /// Get checkout history for an equipment item.
  Future<List<EquipmentCheckout>> getCheckoutsForItem(String itemId) async {
    try {
      final response = await supabase
          .from('equipment_checkouts')
          .select()
          .eq('equipment_item_id', itemId)
          .isFilter('deleted_at', null)
          .order('checked_out_at', ascending: false);

      return (response as List)
          .map((row) => EquipmentCheckout.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw DatabaseError('Failed to fetch checkouts: $e', cause: e);
    }
  }

  /// Get all active (unreturned) checkouts for the current user.
  Future<List<EquipmentCheckout>> getMyActiveCheckouts() async {
    try {
      final userId = currentUser?.id;
      if (userId == null) throw AuthError('Not authenticated');

      final response = await supabase
          .from('equipment_checkouts')
          .select('*, equipment_items(name, category, photo_url)')
          .eq('checked_out_by', userId)
          .isFilter('checked_in_at', null)
          .isFilter('deleted_at', null)
          .order('checked_out_at', ascending: false);

      return (response as List)
          .map((row) => EquipmentCheckout.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (e is AppError) rethrow;
      throw DatabaseError('Failed to fetch my checkouts: $e', cause: e);
    }
  }

  /// Get all active checkouts company-wide (for admin view).
  Future<List<EquipmentCheckout>> getAllActiveCheckouts() async {
    try {
      final response = await supabase
          .from('equipment_checkouts')
          .select('*, equipment_items(name, category)')
          .isFilter('checked_in_at', null)
          .isFilter('deleted_at', null)
          .order('checked_out_at', ascending: false);

      return (response as List)
          .map((row) => EquipmentCheckout.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw DatabaseError('Failed to fetch active checkouts: $e', cause: e);
    }
  }

  /// Get overdue checkouts (not returned past expected_return_date).
  Future<List<EquipmentCheckout>> getOverdueCheckouts() async {
    try {
      final now = DateTime.now().toIso8601String().split('T').first;

      final response = await supabase
          .from('equipment_checkouts')
          .select('*, equipment_items(name, category)')
          .isFilter('checked_in_at', null)
          .isFilter('deleted_at', null)
          .not('expected_return_date', 'is', null)
          .lte('expected_return_date', now)
          .order('expected_return_date');

      return (response as List)
          .map((row) => EquipmentCheckout.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw DatabaseError('Failed to fetch overdue checkouts: $e', cause: e);
    }
  }

  /// Checkout equipment.
  Future<EquipmentCheckout> checkout({
    required String equipmentItemId,
    required EquipmentCondition condition,
    DateTime? expectedReturnDate,
    String? jobId,
    String? notes,
    String? photoOutUrl,
  }) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) throw AuthError('Not authenticated');
      final companyId = currentUser!.appMetadata['company_id'] as String?;
      if (companyId == null) throw AuthError('No company');

      final response = await supabase
          .from('equipment_checkouts')
          .insert({
            'company_id': companyId,
            'equipment_item_id': equipmentItemId,
            'checked_out_by': userId,
            'checkout_condition': condition.dbValue,
            'expected_return_date': expectedReturnDate?.toIso8601String().split('T').first,
            'job_id': jobId,
            'notes': notes,
            'photo_out_url': photoOutUrl,
          })
          .select()
          .single();

      return EquipmentCheckout.fromJson(response);
    } catch (e) {
      if (e is AppError) rethrow;
      throw DatabaseError('Failed to checkout equipment: $e', cause: e);
    }
  }

  /// Check in (return) equipment.
  Future<EquipmentCheckout> checkin({
    required String checkoutId,
    required EquipmentCondition condition,
    String? notes,
    String? photoInUrl,
  }) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) throw AuthError('Not authenticated');

      final response = await supabase
          .from('equipment_checkouts')
          .update({
            'checked_in_at': DateTime.now().toUtc().toIso8601String(),
            'checked_in_by': userId,
            'checkin_condition': condition.dbValue,
            'notes': notes,
            'photo_in_url': photoInUrl,
          })
          .eq('id', checkoutId)
          .select()
          .single();

      return EquipmentCheckout.fromJson(response);
    } catch (e) {
      if (e is AppError) rethrow;
      throw DatabaseError('Failed to checkin equipment: $e', cause: e);
    }
  }
}
