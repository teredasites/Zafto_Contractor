// ZAFTO TPI Inspection Repository — Supabase Backend
// CRUD for the tpi_scheduling table.

import '../core/supabase_client.dart';
import '../core/errors.dart';
import '../models/tpi_inspection.dart';

class TpiInspectionRepository {
  static const _table = 'tpi_scheduling';

  Future<TpiInspection> createInspection(TpiInspection inspection) async {
    try {
      final response = await supabase
          .from(_table)
          .insert(inspection.toInsertJson())
          .select()
          .single();

      return TpiInspection.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to create TPI inspection',
        userMessage: 'Could not save inspection. Please try again.',
        cause: e,
      );
    }
  }

  Future<TpiInspection> updateInspection(
      String id, TpiInspection inspection) async {
    try {
      final response = await supabase
          .from(_table)
          .update(inspection.toUpdateJson())
          .eq('id', id)
          .select()
          .single();

      return TpiInspection.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to update TPI inspection',
        userMessage: 'Could not update inspection. Please try again.',
        cause: e,
      );
    }
  }

  Future<List<TpiInspection>> getInspectionsByClaim(String claimId) async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .eq('claim_id', claimId)
          .order('scheduled_date', ascending: false);

      return (response as List)
          .map((row) => TpiInspection.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load inspections for claim $claimId',
        userMessage: 'Could not load inspections.',
        cause: e,
      );
    }
  }

  Future<List<TpiInspection>> getInspectionsByJob(String jobId) async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .eq('job_id', jobId)
          .order('scheduled_date', ascending: false);

      return (response as List)
          .map((row) => TpiInspection.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load inspections for job $jobId',
        userMessage: 'Could not load inspections.',
        cause: e,
      );
    }
  }

  Future<TpiInspection?> getInspection(String id) async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return TpiInspection.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to load inspection $id',
        userMessage: 'Could not load inspection.',
        cause: e,
      );
    }
  }

  Future<void> deleteInspection(String id) async {
    try {
      await supabase.from(_table).delete().eq('id', id);
    } catch (e) {
      throw DatabaseError(
        'Failed to delete inspection',
        userMessage: 'Could not delete inspection.',
        cause: e,
      );
    }
  }
}
