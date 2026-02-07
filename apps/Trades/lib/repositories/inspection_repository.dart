// ZAFTO Property Management Inspection Repository
// Created: Property Management feature
//
// Supabase CRUD for pm_inspections and pm_inspection_items tables.
// RLS handles company scoping automatically.

import '../core/errors.dart';
import '../core/supabase_client.dart';
import '../models/inspection.dart';

class InspectionRepository {
  static const _inspectionsTable = 'pm_inspections';
  static const _itemsTable = 'pm_inspection_items';

  // ============================================================
  // INSPECTIONS — READ
  // ============================================================

  Future<List<PmInspection>> getInspections({
    String? propertyId,
    String? unitId,
  }) async {
    try {
      var query = supabase.from(_inspectionsTable).select();
      if (propertyId != null) {
        query = query.eq('property_id', propertyId);
      }
      if (unitId != null) {
        query = query.eq('unit_id', unitId);
      }
      final response = await query.order('created_at', ascending: false);
      return (response as List)
          .map((row) => PmInspection.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to fetch inspections: $e',
        userMessage: 'Could not load inspections. Please try again.',
        cause: e,
      );
    }
  }

  Future<PmInspection?> getInspection(String id) async {
    try {
      final response = await supabase
          .from(_inspectionsTable)
          .select()
          .eq('id', id)
          .maybeSingle();
      if (response == null) return null;
      return PmInspection.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to fetch inspection: $e',
        userMessage: 'Could not load inspection. Please try again.',
        cause: e,
      );
    }
  }

  // ============================================================
  // INSPECTIONS — WRITE
  // ============================================================

  Future<PmInspection> createInspection(PmInspection i) async {
    try {
      final response = await supabase
          .from(_inspectionsTable)
          .insert(i.toInsertJson())
          .select()
          .single();
      return PmInspection.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to create inspection: $e',
        userMessage: 'Could not create inspection. Please try again.',
        cause: e,
      );
    }
  }

  Future<PmInspection> updateInspection(String id, PmInspection i) async {
    try {
      final response = await supabase
          .from(_inspectionsTable)
          .update(i.toUpdateJson())
          .eq('id', id)
          .select()
          .single();
      return PmInspection.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to update inspection: $e',
        userMessage: 'Could not update inspection. Please try again.',
        cause: e,
      );
    }
  }

  Future<PmInspection> completeInspection(
    String id,
    ItemCondition overall,
    int score,
  ) async {
    try {
      final response = await supabase
          .from(_inspectionsTable)
          .update({
            'status': 'completed',
            'overall_condition': overall.name,
            'score': score,
            'completed_date': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', id)
          .select()
          .single();
      return PmInspection.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to complete inspection: $e',
        userMessage: 'Could not complete inspection. Please try again.',
        cause: e,
      );
    }
  }

  // ============================================================
  // INSPECTION ITEMS — READ
  // ============================================================

  Future<List<PmInspectionItem>> getInspectionItems(
    String inspectionId,
  ) async {
    try {
      final response = await supabase
          .from(_itemsTable)
          .select()
          .eq('inspection_id', inspectionId)
          .order('sort_order', ascending: true);
      return (response as List)
          .map((row) => PmInspectionItem.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to fetch inspection items: $e',
        userMessage: 'Could not load inspection items. Please try again.',
        cause: e,
      );
    }
  }

  // ============================================================
  // INSPECTION ITEMS — WRITE
  // ============================================================

  Future<PmInspectionItem> addInspectionItem(PmInspectionItem item) async {
    try {
      final response = await supabase
          .from(_itemsTable)
          .insert(item.toInsertJson())
          .select()
          .single();
      return PmInspectionItem.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to add inspection item: $e',
        userMessage: 'Could not add inspection item. Please try again.',
        cause: e,
      );
    }
  }

  Future<PmInspectionItem> updateInspectionItem(
    String id,
    PmInspectionItem item,
  ) async {
    try {
      final response = await supabase
          .from(_itemsTable)
          .update(item.toUpdateJson())
          .eq('id', id)
          .select()
          .single();
      return PmInspectionItem.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to update inspection item: $e',
        userMessage: 'Could not update inspection item. Please try again.',
        cause: e,
      );
    }
  }
}
