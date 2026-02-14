// ZAFTO Schedule Project Repository
// CRUD for schedule_projects table. RLS handles company scoping.
// GC1: Phase GC foundation.

import '../core/errors.dart';
import '../core/supabase_client.dart';
import '../models/schedule_project.dart';

class ScheduleProjectRepository {
  Future<List<ScheduleProject>> getProjects() async {
    try {
      final response = await supabase
          .from('schedule_projects')
          .select()
          .isFilter('deleted_at', null)
          .order('updated_at', ascending: false);
      return (response as List)
          .map((row) => ScheduleProject.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw DatabaseError('Failed to fetch schedule projects: $e', cause: e);
    }
  }

  Future<ScheduleProject?> getProject(String id) async {
    try {
      final response = await supabase
          .from('schedule_projects')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (response == null) return null;
      return ScheduleProject.fromJson(response);
    } catch (e) {
      throw DatabaseError('Failed to fetch schedule project: $e', cause: e);
    }
  }

  Future<List<ScheduleProject>> getProjectsForJob(String jobId) async {
    try {
      final response = await supabase
          .from('schedule_projects')
          .select()
          .eq('job_id', jobId)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false);
      return (response as List)
          .map((row) => ScheduleProject.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw DatabaseError('Failed to fetch job schedules: $e', cause: e);
    }
  }

  Future<ScheduleProject> createProject({
    required String companyId,
    required String name,
    String? jobId,
    String? description,
    DateTime? plannedStart,
    DateTime? plannedFinish,
    String? defaultCalendarId,
  }) async {
    try {
      final data = <String, dynamic>{
        'company_id': companyId,
        'name': name,
        'status': 'draft',
      };
      if (jobId != null) data['job_id'] = jobId;
      if (description != null) data['description'] = description;
      if (plannedStart != null) {
        data['planned_start'] = '${plannedStart.year}-${plannedStart.month.toString().padLeft(2, '0')}-${plannedStart.day.toString().padLeft(2, '0')}';
      }
      if (plannedFinish != null) {
        data['planned_finish'] = '${plannedFinish.year}-${plannedFinish.month.toString().padLeft(2, '0')}-${plannedFinish.day.toString().padLeft(2, '0')}';
      }
      if (defaultCalendarId != null) data['default_calendar_id'] = defaultCalendarId;

      final response = await supabase
          .from('schedule_projects')
          .insert(data)
          .select()
          .single();
      return ScheduleProject.fromJson(response);
    } catch (e) {
      throw DatabaseError('Failed to create schedule project: $e', cause: e);
    }
  }

  Future<void> updateProject(String id, Map<String, dynamic> updates) async {
    try {
      await supabase.from('schedule_projects').update(updates).eq('id', id);
    } catch (e) {
      throw DatabaseError('Failed to update schedule project: $e', cause: e);
    }
  }

  Future<void> deleteProject(String id) async {
    try {
      await supabase.from('schedule_projects').update({
        'deleted_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', id);
    } catch (e) {
      throw DatabaseError('Failed to delete schedule project: $e', cause: e);
    }
  }
}
