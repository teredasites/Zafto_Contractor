// ZAFTO Daily Log Repository — Supabase Backend
// CRUD for the daily_logs table. One log per job per day.

import '../core/supabase_client.dart';
import '../core/errors.dart';
import '../models/daily_log.dart';

class DailyLogRepository {
  static const _table = 'daily_logs';

  // Create a new daily log.
  Future<DailyLog> createLog(DailyLog log) async {
    try {
      final response = await supabase
          .from(_table)
          .insert(log.toInsertJson())
          .select()
          .single();

      return DailyLog.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to create daily log',
        userMessage: 'Could not save daily log. Please try again.',
        cause: e,
      );
    }
  }

  // Get all logs for a job (ordered by date descending).
  Future<List<DailyLog>> getLogsByJob(String jobId) async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .eq('job_id', jobId)
          .order('log_date', ascending: false);

      return (response as List)
          .map((row) => DailyLog.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load daily logs for job $jobId',
        userMessage: 'Could not load logs.',
        cause: e,
      );
    }
  }

  // Get today's log for a job (returns null if none exists).
  Future<DailyLog?> getTodaysLog(String jobId) async {
    try {
      final today = DateTime.now();
      final dateStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final response = await supabase
          .from(_table)
          .select()
          .eq('job_id', jobId)
          .eq('log_date', dateStr)
          .maybeSingle();

      if (response == null) return null;
      return DailyLog.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to load today\'s log',
        userMessage: 'Could not load today\'s log.',
        cause: e,
      );
    }
  }

  // Update an existing log.
  Future<DailyLog> updateLog(String id, Map<String, dynamic> updates) async {
    try {
      final response = await supabase
          .from(_table)
          .update(updates)
          .eq('id', id)
          .select()
          .single();

      return DailyLog.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to update daily log',
        userMessage: 'Could not update log.',
        cause: e,
      );
    }
  }

  // Upsert: create if new, update if existing (same job + date).
  Future<DailyLog> upsertLog(DailyLog log) async {
    try {
      final data = log.isNew ? log.toInsertJson() : log.toUpdateJson();

      if (log.isNew) {
        return createLog(log);
      } else {
        return updateLog(log.id, data);
      }
    } catch (e) {
      throw DatabaseError(
        'Failed to save daily log',
        userMessage: 'Could not save log.',
        cause: e,
      );
    }
  }
}
