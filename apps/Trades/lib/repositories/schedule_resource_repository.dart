// ZAFTO Schedule Resource Repository
// CRUD for schedule_resources + schedule_task_resources tables.
// RLS handles company scoping.
// GC1: Phase GC foundation.

import '../core/errors.dart';
import '../core/supabase_client.dart';
import '../models/schedule_resource.dart';
import '../models/schedule_task_resource.dart';

class ScheduleResourceRepository {
  // =========================================================================
  // RESOURCES
  // =========================================================================

  Future<List<ScheduleResource>> getResources() async {
    try {
      final response = await supabase
          .from('schedule_resources')
          .select()
          .isFilter('deleted_at', null)
          .order('name', ascending: true);
      return (response as List)
          .map((row) => ScheduleResource.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw DatabaseError('Failed to fetch resources: $e', cause: e);
    }
  }

  Future<List<ScheduleResource>> getResourcesByType(String type) async {
    try {
      final response = await supabase
          .from('schedule_resources')
          .select()
          .eq('resource_type', type)
          .isFilter('deleted_at', null)
          .order('name', ascending: true);
      return (response as List)
          .map((row) => ScheduleResource.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw DatabaseError('Failed to fetch resources by type: $e', cause: e);
    }
  }

  Future<ScheduleResource> createResource(ScheduleResource resource) async {
    try {
      final response = await supabase
          .from('schedule_resources')
          .insert(resource.toInsertJson())
          .select()
          .single();
      return ScheduleResource.fromJson(response);
    } catch (e) {
      throw DatabaseError('Failed to create resource: $e', cause: e);
    }
  }

  Future<void> updateResource(String id, Map<String, dynamic> updates) async {
    try {
      await supabase.from('schedule_resources').update(updates).eq('id', id);
    } catch (e) {
      throw DatabaseError('Failed to update resource: $e', cause: e);
    }
  }

  Future<void> deleteResource(String id) async {
    try {
      await supabase.from('schedule_resources').update({
        'deleted_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', id);
    } catch (e) {
      throw DatabaseError('Failed to delete resource: $e', cause: e);
    }
  }

  // =========================================================================
  // TASK RESOURCE ASSIGNMENTS
  // =========================================================================

  Future<List<ScheduleTaskResource>> getTaskResources(String taskId) async {
    try {
      final response = await supabase
          .from('schedule_task_resources')
          .select()
          .eq('task_id', taskId)
          .order('created_at', ascending: true);
      return (response as List)
          .map((row) =>
              ScheduleTaskResource.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw DatabaseError('Failed to fetch task resources: $e', cause: e);
    }
  }

  Future<ScheduleTaskResource> assignResource(
      ScheduleTaskResource assignment) async {
    try {
      final response = await supabase
          .from('schedule_task_resources')
          .insert(assignment.toInsertJson())
          .select()
          .single();
      return ScheduleTaskResource.fromJson(response);
    } catch (e) {
      throw DatabaseError('Failed to assign resource: $e', cause: e);
    }
  }

  Future<void> updateTaskResource(
      String id, Map<String, dynamic> updates) async {
    try {
      await supabase
          .from('schedule_task_resources')
          .update(updates)
          .eq('id', id);
    } catch (e) {
      throw DatabaseError('Failed to update task resource: $e', cause: e);
    }
  }

  Future<void> removeTaskResource(String id) async {
    try {
      await supabase.from('schedule_task_resources').delete().eq('id', id);
    } catch (e) {
      throw DatabaseError('Failed to remove task resource: $e', cause: e);
    }
  }
}
