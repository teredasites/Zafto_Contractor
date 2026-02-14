// ZAFTO Schedule Baseline Repository
// CRUD for schedule_baselines + schedule_baseline_tasks tables.
// RLS handles company scoping.
// GC1: Phase GC foundation.

import '../core/errors.dart';
import '../core/supabase_client.dart';
import '../models/schedule_baseline.dart';
import '../models/schedule_baseline_task.dart';

class ScheduleBaselineRepository {
  Future<List<ScheduleBaseline>> getBaselines(String projectId) async {
    try {
      final response = await supabase
          .from('schedule_baselines')
          .select()
          .eq('project_id', projectId)
          .order('baseline_number', ascending: true);
      return (response as List)
          .map((row) =>
              ScheduleBaseline.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw DatabaseError('Failed to fetch baselines: $e', cause: e);
    }
  }

  Future<ScheduleBaseline?> getActiveBaseline(String projectId) async {
    try {
      final response = await supabase
          .from('schedule_baselines')
          .select()
          .eq('project_id', projectId)
          .eq('is_active', true)
          .order('baseline_number', ascending: false)
          .limit(1)
          .maybeSingle();
      if (response == null) return null;
      return ScheduleBaseline.fromJson(response);
    } catch (e) {
      throw DatabaseError('Failed to fetch active baseline: $e', cause: e);
    }
  }

  Future<ScheduleBaseline> createBaseline(ScheduleBaseline baseline) async {
    try {
      final response = await supabase
          .from('schedule_baselines')
          .insert(baseline.toInsertJson())
          .select()
          .single();
      return ScheduleBaseline.fromJson(response);
    } catch (e) {
      throw DatabaseError('Failed to create baseline: $e', cause: e);
    }
  }

  Future<void> deactivateBaseline(String id) async {
    try {
      await supabase
          .from('schedule_baselines')
          .update({'is_active': false})
          .eq('id', id);
    } catch (e) {
      throw DatabaseError('Failed to deactivate baseline: $e', cause: e);
    }
  }

  Future<void> deleteBaseline(String id) async {
    try {
      await supabase.from('schedule_baselines').delete().eq('id', id);
    } catch (e) {
      throw DatabaseError('Failed to delete baseline: $e', cause: e);
    }
  }

  // =========================================================================
  // BASELINE TASKS
  // =========================================================================

  Future<List<ScheduleBaselineTask>> getBaselineTasks(
      String baselineId) async {
    try {
      final response = await supabase
          .from('schedule_baseline_tasks')
          .select()
          .eq('baseline_id', baselineId)
          .order('created_at', ascending: true);
      return (response as List)
          .map((row) =>
              ScheduleBaselineTask.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw DatabaseError('Failed to fetch baseline tasks: $e', cause: e);
    }
  }

  Future<void> captureBaseline({
    required ScheduleBaseline baseline,
    required List<ScheduleBaselineTask> tasks,
  }) async {
    try {
      final baselineResponse = await supabase
          .from('schedule_baselines')
          .insert(baseline.toInsertJson())
          .select()
          .single();

      final baselineId = baselineResponse['id'] as String;

      if (tasks.isNotEmpty) {
        final taskInserts = tasks.map((t) {
          final json = t.toInsertJson();
          json['baseline_id'] = baselineId;
          return json;
        }).toList();

        await supabase.from('schedule_baseline_tasks').insert(taskInserts);
      }
    } catch (e) {
      throw DatabaseError('Failed to capture baseline: $e', cause: e);
    }
  }
}
