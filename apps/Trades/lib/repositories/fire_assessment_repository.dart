// ZAFTO Fire Assessment Repository — Supabase Backend
// CRUD for fire_assessments table. Sprint REST1.

import '../core/supabase_client.dart';
import '../core/errors.dart';
import '../models/fire_assessment.dart';

class FireAssessmentRepository {
  static const _table = 'fire_assessments';

  Future<FireAssessment> create(FireAssessment assessment) async {
    try {
      final response = await supabase
          .from(_table)
          .insert(assessment.toInsertJson())
          .select()
          .single();

      return FireAssessment.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to create fire assessment',
        userMessage: 'Could not save fire assessment. Please try again.',
        cause: e,
      );
    }
  }

  Future<FireAssessment> update(String id, FireAssessment assessment) async {
    try {
      final response = await supabase
          .from(_table)
          .update(assessment.toUpdateJson())
          .eq('id', id)
          .select()
          .single();

      return FireAssessment.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to update fire assessment',
        userMessage: 'Could not update assessment. Please try again.',
        cause: e,
      );
    }
  }

  Future<FireAssessment?> getById(String id) async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .eq('id', id)
          .is_('deleted_at', null)
          .maybeSingle();

      if (response == null) return null;
      return FireAssessment.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to load fire assessment',
        userMessage: 'Could not load assessment.',
        cause: e,
      );
    }
  }

  Future<List<FireAssessment>> getByJob(String jobId) async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .eq('job_id', jobId)
          .is_('deleted_at', null)
          .order('created_at', ascending: false);

      return (response as List)
          .map((row) => FireAssessment.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load fire assessments for job $jobId',
        userMessage: 'Could not load assessments.',
        cause: e,
      );
    }
  }

  Future<List<FireAssessment>> getByClaim(String claimId) async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .eq('insurance_claim_id', claimId)
          .is_('deleted_at', null)
          .order('created_at', ascending: false);

      return (response as List)
          .map((row) => FireAssessment.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load fire assessments for claim $claimId',
        userMessage: 'Could not load assessments.',
        cause: e,
      );
    }
  }

  Future<List<FireAssessment>> getAll() async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .is_('deleted_at', null)
          .order('created_at', ascending: false);

      return (response as List)
          .map((row) => FireAssessment.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load fire assessments',
        userMessage: 'Could not load assessments.',
        cause: e,
      );
    }
  }

  Future<void> softDelete(String id) async {
    try {
      await supabase
          .from(_table)
          .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', id);
    } catch (e) {
      throw DatabaseError(
        'Failed to delete fire assessment',
        userMessage: 'Could not delete assessment.',
        cause: e,
      );
    }
  }

  Future<void> updateStatus(String id, AssessmentStatus status) async {
    try {
      await supabase
          .from(_table)
          .update({'assessment_status': status.dbValue})
          .eq('id', id);
    } catch (e) {
      throw DatabaseError(
        'Failed to update assessment status',
        userMessage: 'Could not update status.',
        cause: e,
      );
    }
  }
}
