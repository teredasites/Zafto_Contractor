// ZAFTO Vendor Repository — Supabase Backend
// CRUD for the vendors table.

import '../core/supabase_client.dart';
import '../core/errors.dart';
import '../models/vendor.dart';

class VendorRepository {
  static const _table = 'vendors';

  // Create a new vendor.
  Future<Vendor> createVendor(Vendor vendor) async {
    try {
      final response = await supabase
          .from(_table)
          .insert(vendor.toInsertJson())
          .select()
          .single();

      return Vendor.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to create vendor',
        userMessage: 'Could not save vendor. Please try again.',
        cause: e,
      );
    }
  }

  // Get all vendors with optional active filter.
  Future<List<Vendor>> getVendors({
    int limit = 100,
    bool? isActive,
  }) async {
    try {
      var query = supabase
          .from(_table)
          .select()
          .isFilter('deleted_at', null);

      if (isActive != null) {
        query = query.eq('is_active', isActive);
      }

      final response = await query
          .order('vendor_name')
          .limit(limit);

      return (response as List)
          .map((row) => Vendor.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load vendors',
        userMessage: 'Could not load vendors.',
        cause: e,
      );
    }
  }

  // Get a single vendor by ID.
  Future<Vendor?> getVendor(String id) async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return Vendor.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to load vendor $id',
        userMessage: 'Could not load vendor.',
        cause: e,
      );
    }
  }

  // Search vendors by name.
  Future<List<Vendor>> searchVendors(String query) async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .ilike('vendor_name', '%$query%')
          .isFilter('deleted_at', null)
          .order('vendor_name')
          .limit(50);

      return (response as List)
          .map((row) => Vendor.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to search vendors',
        userMessage: 'Could not search vendors.',
        cause: e,
      );
    }
  }

  // Update a vendor.
  Future<Vendor> updateVendor(
      String id, Map<String, dynamic> updates) async {
    try {
      final response = await supabase
          .from(_table)
          .update(updates)
          .eq('id', id)
          .select()
          .single();

      return Vendor.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to update vendor',
        userMessage: 'Could not update vendor.',
        cause: e,
      );
    }
  }

  // Soft delete a vendor.
  Future<void> deleteVendor(String id) async {
    try {
      await supabase
          .from(_table)
          .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', id);
    } catch (e) {
      throw DatabaseError(
        'Failed to delete vendor',
        userMessage: 'Could not delete vendor.',
        cause: e,
      );
    }
  }
}
