// ZAFTO Tenant Repository
// Created: Property Management feature
//
// Supabase CRUD for tenants table.
// RLS handles company scoping automatically.

import '../core/errors.dart';
import '../core/supabase_client.dart';
import '../models/property.dart';

class TenantRepository {
  static const _table = 'tenants';

  // ============================================================
  // READ
  // ============================================================

  Future<List<Tenant>> getTenants() async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .order('name', ascending: true);
      return (response as List)
          .map((row) => Tenant.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to fetch tenants: $e',
        userMessage: 'Could not load tenants. Please try again.',
        cause: e,
      );
    }
  }

  Future<Tenant?> getTenant(String id) async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .eq('id', id)
          .maybeSingle();
      if (response == null) return null;
      return Tenant.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to fetch tenant: $e',
        userMessage: 'Could not load tenant. Please try again.',
        cause: e,
      );
    }
  }

  Future<List<Tenant>> getTenantsByProperty(String propertyId) async {
    try {
      final response = await supabase
          .from(_table)
          .select('*, leases!inner(property_id)')
          .eq('leases.property_id', propertyId)
          .order('name', ascending: true);
      return (response as List)
          .map((row) => Tenant.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to fetch tenants for property: $e',
        userMessage: 'Could not load tenants. Please try again.',
        cause: e,
      );
    }
  }

  Future<List<Tenant>> searchTenants(String query) async {
    try {
      final q = '%$query%';
      final response = await supabase
          .from(_table)
          .select()
          .or('name.ilike.$q,email.ilike.$q,phone.ilike.$q')
          .order('name', ascending: true);
      return (response as List)
          .map((row) => Tenant.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to search tenants: $e',
        userMessage: 'Could not search tenants. Please try again.',
        cause: e,
      );
    }
  }

  // ============================================================
  // WRITE
  // ============================================================

  Future<Tenant> createTenant(Tenant t) async {
    try {
      final response = await supabase
          .from(_table)
          .insert(t.toInsertJson())
          .select()
          .single();
      return Tenant.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to create tenant: $e',
        userMessage: 'Could not create tenant. Please try again.',
        cause: e,
      );
    }
  }

  Future<Tenant> updateTenant(String id, Tenant t) async {
    try {
      final response = await supabase
          .from(_table)
          .update(t.toUpdateJson())
          .eq('id', id)
          .select()
          .single();
      return Tenant.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to update tenant: $e',
        userMessage: 'Could not update tenant. Please try again.',
        cause: e,
      );
    }
  }
}
