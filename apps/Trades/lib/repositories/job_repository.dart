// ZAFTO Job Repository
// Created: Sprint B1c (Session 42 — crash recovery)
//
// Supabase CRUD for jobs table.
// RLS handles company scoping automatically.

import '../core/errors.dart';
import '../core/supabase_client.dart';
import '../models/job.dart';

class JobRepository {
  // ============================================================
  // READ
  // ============================================================

  Future<List<Job>> getJobs() async {
    try {
      final response = await supabase
          .from('jobs')
          .select()
          .isFilter('deleted_at', null)
          .order('updated_at', ascending: false);
      return (response as List).map((row) => Job.fromJson(row)).toList();
    } catch (e) {
      throw DatabaseError('Failed to fetch jobs: $e', cause: e);
    }
  }

  Future<Job?> getJob(String id) async {
    try {
      final response = await supabase
          .from('jobs')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (response == null) return null;
      return Job.fromJson(response);
    } catch (e) {
      throw DatabaseError('Failed to fetch job: $e', cause: e);
    }
  }

  Future<List<Job>> getJobsByStatus(JobStatus status) async {
    try {
      final response = await supabase
          .from('jobs')
          .select()
          .eq('status', status.name)
          .isFilter('deleted_at', null)
          .order('scheduled_start', ascending: true);
      return (response as List).map((row) => Job.fromJson(row)).toList();
    } catch (e) {
      throw DatabaseError('Failed to fetch jobs by status: $e', cause: e);
    }
  }

  Future<List<Job>> getJobsByCustomer(String customerId) async {
    try {
      final response = await supabase
          .from('jobs')
          .select()
          .eq('customer_id', customerId)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false);
      return (response as List).map((row) => Job.fromJson(row)).toList();
    } catch (e) {
      throw DatabaseError('Failed to fetch jobs for customer: $e', cause: e);
    }
  }

  Future<List<Job>> searchJobs(String query) async {
    try {
      final q = '%$query%';
      final response = await supabase
          .from('jobs')
          .select()
          .or('title.ilike.$q,customer_name.ilike.$q,address.ilike.$q,description.ilike.$q')
          .isFilter('deleted_at', null)
          .order('updated_at', ascending: false);
      return (response as List).map((row) => Job.fromJson(row)).toList();
    } catch (e) {
      throw DatabaseError('Failed to search jobs: $e', cause: e);
    }
  }

  // ============================================================
  // WRITE
  // ============================================================

  Future<Job> createJob(Job job) async {
    try {
      final response = await supabase
          .from('jobs')
          .insert(job.toInsertJson())
          .select()
          .single();
      return Job.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to create job: $e',
        userMessage: 'Could not create job. Please try again.',
        cause: e,
      );
    }
  }

  Future<Job> updateJob(String id, Job job) async {
    try {
      final response = await supabase
          .from('jobs')
          .update(job.toUpdateJson())
          .eq('id', id)
          .select()
          .single();
      return Job.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to update job: $e',
        userMessage: 'Could not update job. Please try again.',
        cause: e,
      );
    }
  }

  Future<Job> updateJobStatus(String id, JobStatus status) async {
    try {
      final data = <String, dynamic>{'status': status.name};
      if (status == JobStatus.inProgress) {
        data['started_at'] = DateTime.now().toUtc().toIso8601String();
      } else if (status == JobStatus.completed) {
        data['completed_at'] = DateTime.now().toUtc().toIso8601String();
      }
      final response = await supabase
          .from('jobs')
          .update(data)
          .eq('id', id)
          .select()
          .single();
      return Job.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to update job status: $e',
        userMessage: 'Could not update job status. Please try again.',
        cause: e,
      );
    }
  }

  Future<void> deleteJob(String id) async {
    try {
      await supabase
          .from('jobs')
          .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', id);
    } catch (e) {
      throw DatabaseError(
        'Failed to delete job: $e',
        userMessage: 'Could not delete job. Please try again.',
        cause: e,
      );
    }
  }
}
