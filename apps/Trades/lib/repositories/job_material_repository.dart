// ZAFTO Job Material Repository — Supabase Backend
// CRUD for the job_materials table.

import '../core/supabase_client.dart';
import '../core/errors.dart';
import '../models/job_material.dart';

class JobMaterialRepository {
  static const _table = 'job_materials';

  // Create a new material entry.
  Future<JobMaterial> createMaterial(JobMaterial material) async {
    try {
      final response = await supabase
          .from(_table)
          .insert(material.toInsertJson())
          .select()
          .single();

      return JobMaterial.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to create material entry',
        userMessage: 'Could not save material. Please try again.',
        cause: e,
      );
    }
  }

  // Get all materials for a job.
  Future<List<JobMaterial>> getMaterialsByJob(String jobId) async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .eq('job_id', jobId)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false);

      return (response as List)
          .map((row) => JobMaterial.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load materials for job $jobId',
        userMessage: 'Could not load materials.',
        cause: e,
      );
    }
  }

  // Get materials filtered by category.
  Future<List<JobMaterial>> getMaterialsByCategory(
      String jobId, MaterialCategory category) async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .eq('job_id', jobId)
          .eq('category', category.dbValue)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false);

      return (response as List)
          .map((row) => JobMaterial.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load ${category.label} items',
        userMessage: 'Could not load materials.',
        cause: e,
      );
    }
  }

  // Update a material entry.
  Future<JobMaterial> updateMaterial(
      String id, Map<String, dynamic> updates) async {
    try {
      final response = await supabase
          .from(_table)
          .update(updates)
          .eq('id', id)
          .select()
          .single();

      return JobMaterial.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to update material',
        userMessage: 'Could not update material.',
        cause: e,
      );
    }
  }

  // Soft delete a material entry.
  Future<void> deleteMaterial(String id) async {
    try {
      await supabase
          .from(_table)
          .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', id);
    } catch (e) {
      throw DatabaseError(
        'Failed to delete material',
        userMessage: 'Could not delete material.',
        cause: e,
      );
    }
  }
}
