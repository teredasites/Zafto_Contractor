// ZAFTO Inspection Deficiency Repository
// Created: INS1 — Inspector Deep Buildout
//
// Supabase CRUD for inspection_deficiencies table.
// RLS handles company scoping automatically.

import '../core/errors.dart';
import '../core/supabase_client.dart';
import '../models/inspection.dart';

class InspectionDeficiencyRepository {
  static const _table = 'inspection_deficiencies';

  // READ

  Future<List<InspectionDeficiency>> getDeficiencies({
    String? inspectionId,
    DeficiencyStatus? status,
    DeficiencySeverity? severity,
  }) async {
    try {
      var query = supabase.from(_table).select();
      if (inspectionId != null) {
        query = query.eq('inspection_id', inspectionId);
      }
      if (status != null) {
        query = query.eq('status', PmInspection.enumToDb(status));
      }
      if (severity != null) {
        query = query.eq('severity', PmInspection.enumToDb(severity));
      }
      final response = await query.order('created_at', ascending: false);
      return (response as List)
          .map((row) => InspectionDeficiency.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to fetch deficiencies: $e',
        userMessage: 'Could not load deficiencies. Please try again.',
        cause: e,
      );
    }
  }

  Future<InspectionDeficiency?> getDeficiency(String id) async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .eq('id', id)
          .maybeSingle();
      if (response == null) return null;
      return InspectionDeficiency.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to fetch deficiency: $e',
        userMessage: 'Could not load deficiency. Please try again.',
        cause: e,
      );
    }
  }

  // WRITE

  Future<InspectionDeficiency> createDeficiency(
    InspectionDeficiency d,
  ) async {
    try {
      final response = await supabase
          .from(_table)
          .insert(d.toInsertJson())
          .select()
          .single();
      return InspectionDeficiency.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to create deficiency: $e',
        userMessage: 'Could not create deficiency. Please try again.',
        cause: e,
      );
    }
  }

  Future<InspectionDeficiency> updateDeficiency(
    String id,
    InspectionDeficiency d,
  ) async {
    try {
      final response = await supabase
          .from(_table)
          .update(d.toUpdateJson())
          .eq('id', id)
          .select()
          .single();
      return InspectionDeficiency.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to update deficiency: $e',
        userMessage: 'Could not update deficiency. Please try again.',
        cause: e,
      );
    }
  }

  Future<void> updateStatus(String id, DeficiencyStatus status) async {
    try {
      await supabase.from(_table).update({
        'status': PmInspection.enumToDb(status),
      }).eq('id', id);
    } catch (e) {
      throw DatabaseError(
        'Failed to update deficiency status: $e',
        userMessage: 'Could not update status. Please try again.',
        cause: e,
      );
    }
  }
}
