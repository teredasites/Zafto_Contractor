// ZAFTO Property Repository
// Created: Property Management feature
//
// Supabase CRUD for properties and units tables.
// RLS handles company scoping automatically.

import '../core/errors.dart';
import '../core/supabase_client.dart';
import '../models/property.dart';

class PropertyRepository {
  // ============================================================
  // PROPERTIES — READ
  // ============================================================

  Future<List<Property>> getProperties() async {
    try {
      final response = await supabase
          .from('properties')
          .select()
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false);
      return (response as List)
          .map((row) => Property.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to fetch properties: $e',
        userMessage: 'Could not load properties. Please try again.',
        cause: e,
      );
    }
  }

  Future<Property?> getProperty(String id) async {
    try {
      final response = await supabase
          .from('properties')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (response == null) return null;
      return Property.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to fetch property: $e',
        userMessage: 'Could not load property. Please try again.',
        cause: e,
      );
    }
  }

  // ============================================================
  // PROPERTIES — WRITE
  // ============================================================

  Future<Property> createProperty(Property p) async {
    try {
      final response = await supabase
          .from('properties')
          .insert(p.toInsertJson())
          .select()
          .single();
      return Property.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to create property: $e',
        userMessage: 'Could not create property. Please try again.',
        cause: e,
      );
    }
  }

  Future<Property> updateProperty(String id, Property p) async {
    try {
      final response = await supabase
          .from('properties')
          .update(p.toUpdateJson())
          .eq('id', id)
          .select()
          .single();
      return Property.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to update property: $e',
        userMessage: 'Could not update property. Please try again.',
        cause: e,
      );
    }
  }

  Future<void> deleteProperty(String id) async {
    try {
      await supabase
          .from('properties')
          .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', id);
    } catch (e) {
      throw DatabaseError(
        'Failed to delete property: $e',
        userMessage: 'Could not delete property. Please try again.',
        cause: e,
      );
    }
  }

  // ============================================================
  // UNITS — READ
  // ============================================================

  Future<List<Unit>> getUnits({String? propertyId}) async {
    try {
      var query = supabase
          .from('units')
          .select()
          .isFilter('deleted_at', null);
      if (propertyId != null) {
        query = query.eq('property_id', propertyId);
      }
      final response = await query.order('created_at', ascending: false);
      return (response as List).map((row) => Unit.fromJson(row)).toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to fetch units: $e',
        userMessage: 'Could not load units. Please try again.',
        cause: e,
      );
    }
  }

  Future<Unit?> getUnit(String id) async {
    try {
      final response = await supabase
          .from('units')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (response == null) return null;
      return Unit.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to fetch unit: $e',
        userMessage: 'Could not load unit. Please try again.',
        cause: e,
      );
    }
  }

  // ============================================================
  // UNITS — WRITE
  // ============================================================

  Future<Unit> createUnit(Unit u) async {
    try {
      final response = await supabase
          .from('units')
          .insert(u.toInsertJson())
          .select()
          .single();
      return Unit.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to create unit: $e',
        userMessage: 'Could not create unit. Please try again.',
        cause: e,
      );
    }
  }

  Future<Unit> updateUnit(String id, Unit u) async {
    try {
      final response = await supabase
          .from('units')
          .update(u.toUpdateJson())
          .eq('id', id)
          .select()
          .single();
      return Unit.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to update unit: $e',
        userMessage: 'Could not update unit. Please try again.',
        cause: e,
      );
    }
  }

  Future<Unit> updateUnitStatus(String id, UnitStatus status) async {
    try {
      final response = await supabase
          .from('units')
          .update({'status': status.name})
          .eq('id', id)
          .select()
          .single();
      return Unit.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to update unit status: $e',
        userMessage: 'Could not update unit status. Please try again.',
        cause: e,
      );
    }
  }

  Future<void> deleteUnit(String id) async {
    try {
      await supabase
          .from('units')
          .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', id);
    } catch (e) {
      throw DatabaseError(
        'Failed to delete unit: $e',
        userMessage: 'Could not delete unit. Please try again.',
        cause: e,
      );
    }
  }
}
