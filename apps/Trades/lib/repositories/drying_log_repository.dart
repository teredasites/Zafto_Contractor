// ZAFTO Drying Log Repository — Supabase Backend
// INSERT-ONLY for the drying_logs table (immutable legal record).

import '../core/supabase_client.dart';
import '../core/errors.dart';
import '../models/drying_log.dart';

class DryingLogRepository {
  static const _table = 'drying_logs';

  Future<DryingLog> createLog(DryingLog log) async {
    try {
      final response = await supabase
          .from(_table)
          .insert(log.toInsertJson())
          .select()
          .single();

      return DryingLog.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to save drying log',
        userMessage: 'Could not save log entry. Please try again.',
        cause: e,
      );
    }
  }

  // No update/delete — drying logs are immutable (legal compliance)

  Future<List<DryingLog>> getLogsByJob(String jobId) async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .eq('job_id', jobId)
          .order('recorded_at', ascending: false);

      return (response as List)
          .map((row) => DryingLog.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load drying logs for job $jobId',
        userMessage: 'Could not load logs.',
        cause: e,
      );
    }
  }

  Future<List<DryingLog>> getLogsByClaim(String claimId) async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .eq('claim_id', claimId)
          .order('recorded_at', ascending: false);

      return (response as List)
          .map((row) => DryingLog.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load drying logs for claim $claimId',
        userMessage: 'Could not load logs.',
        cause: e,
      );
    }
  }

  Future<List<DryingLog>> getLogsByType(
      String jobId, DryingLogType type) async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .eq('job_id', jobId)
          .eq('log_type', type.dbValue)
          .order('recorded_at', ascending: false);

      return (response as List)
          .map((row) => DryingLog.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load ${type.label} logs',
        userMessage: 'Could not load logs.',
        cause: e,
      );
    }
  }

  Future<DryingLog?> getLog(String id) async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return DryingLog.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to load drying log $id',
        userMessage: 'Could not load log.',
        cause: e,
      );
    }
  }
}
