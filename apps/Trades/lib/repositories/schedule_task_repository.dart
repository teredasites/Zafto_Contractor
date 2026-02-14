// ZAFTO Schedule Task Repository
// CRUD for schedule_tasks + schedule_dependencies tables.
// RLS handles company scoping.
// GC1: Phase GC foundation.

import '../core/errors.dart';
import '../core/supabase_client.dart';
import '../models/schedule_task.dart';
import '../models/schedule_dependency.dart';

class ScheduleTaskRepository {
  // =========================================================================
  // TASKS
  // =========================================================================

  Future<List<ScheduleTask>> getTasksForProject(String projectId) async {
    try {
      final response = await supabase
          .from('schedule_tasks')
          .select()
          .eq('project_id', projectId)
          .isFilter('deleted_at', null)
          .order('sort_order', ascending: true);
      return (response as List)
          .map((row) => ScheduleTask.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw DatabaseError('Failed to fetch schedule tasks: $e', cause: e);
    }
  }

  Future<ScheduleTask?> getTask(String id) async {
    try {
      final response = await supabase
          .from('schedule_tasks')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (response == null) return null;
      return ScheduleTask.fromJson(response);
    } catch (e) {
      throw DatabaseError('Failed to fetch schedule task: $e', cause: e);
    }
  }

  Future<List<ScheduleTask>> getCriticalTasks(String projectId) async {
    try {
      final response = await supabase
          .from('schedule_tasks')
          .select()
          .eq('project_id', projectId)
          .eq('is_critical', true)
          .isFilter('deleted_at', null)
          .order('sort_order', ascending: true);
      return (response as List)
          .map((row) => ScheduleTask.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw DatabaseError('Failed to fetch critical tasks: $e', cause: e);
    }
  }

  Future<ScheduleTask> createTask(ScheduleTask task) async {
    try {
      final response = await supabase
          .from('schedule_tasks')
          .insert(task.toInsertJson())
          .select()
          .single();
      return ScheduleTask.fromJson(response);
    } catch (e) {
      throw DatabaseError('Failed to create schedule task: $e', cause: e);
    }
  }

  Future<void> updateTask(String id, Map<String, dynamic> updates) async {
    try {
      await supabase.from('schedule_tasks').update(updates).eq('id', id);
    } catch (e) {
      throw DatabaseError('Failed to update schedule task: $e', cause: e);
    }
  }

  Future<void> updateProgress(String id, double percentComplete) async {
    try {
      final updates = <String, dynamic>{
        'percent_complete': percentComplete,
      };
      if (percentComplete > 0 && percentComplete < 100) {
        // Auto-set actual_start if not already set
        updates['actual_start'] ??=
            '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';
      }
      if (percentComplete >= 100) {
        updates['actual_finish'] =
            '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';
        updates['remaining_duration'] = 0;
      }
      await supabase.from('schedule_tasks').update(updates).eq('id', id);
    } catch (e) {
      throw DatabaseError('Failed to update task progress: $e', cause: e);
    }
  }

  Future<void> deleteTask(String id) async {
    try {
      await supabase.from('schedule_tasks').update({
        'deleted_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', id);
    } catch (e) {
      throw DatabaseError('Failed to delete schedule task: $e', cause: e);
    }
  }

  Future<void> reorderTasks(List<Map<String, dynamic>> sortUpdates) async {
    try {
      for (final update in sortUpdates) {
        await supabase.from('schedule_tasks').update({
          'sort_order': update['sort_order'],
          'indent_level': update['indent_level'],
          'parent_id': update['parent_id'],
        }).eq('id', update['id']);
      }
    } catch (e) {
      throw DatabaseError('Failed to reorder tasks: $e', cause: e);
    }
  }

  // =========================================================================
  // DEPENDENCIES
  // =========================================================================

  Future<List<ScheduleDependency>> getDependencies(String projectId) async {
    try {
      final response = await supabase
          .from('schedule_dependencies')
          .select()
          .eq('project_id', projectId)
          .order('created_at', ascending: true);
      return (response as List)
          .map((row) =>
              ScheduleDependency.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw DatabaseError('Failed to fetch dependencies: $e', cause: e);
    }
  }

  Future<ScheduleDependency> createDependency(
      ScheduleDependency dep) async {
    try {
      final response = await supabase
          .from('schedule_dependencies')
          .insert(dep.toInsertJson())
          .select()
          .single();
      return ScheduleDependency.fromJson(response);
    } catch (e) {
      throw DatabaseError('Failed to create dependency: $e', cause: e);
    }
  }

  Future<void> deleteDependency(String id) async {
    try {
      await supabase.from('schedule_dependencies').delete().eq('id', id);
    } catch (e) {
      throw DatabaseError('Failed to delete dependency: $e', cause: e);
    }
  }
}
