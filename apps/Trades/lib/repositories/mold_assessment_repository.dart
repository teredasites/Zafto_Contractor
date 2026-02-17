// ZAFTO Mold Assessment Repository — Supabase Backend
// CRUD for mold_assessments + mold_chain_of_custody tables. Sprint REST2.

import '../core/supabase_client.dart';
import '../core/errors.dart';
import '../models/mold_assessment.dart';

class MoldAssessmentRepository {
  static const _table = 'mold_assessments';
  static const _cocTable = 'mold_chain_of_custody';

  // ── Assessments ──

  Future<MoldAssessment> create(MoldAssessment assessment) async {
    try {
      final response = await supabase
          .from(_table)
          .insert(assessment.toInsertJson())
          .select()
          .single();

      return MoldAssessment.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to create mold assessment',
        userMessage: 'Could not save assessment. Please try again.',
        cause: e,
      );
    }
  }

  Future<MoldAssessment> update(String id, Map<String, dynamic> updates) async {
    try {
      final response = await supabase
          .from(_table)
          .update(updates)
          .eq('id', id)
          .select()
          .single();

      return MoldAssessment.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to update mold assessment',
        userMessage: 'Could not update assessment.',
        cause: e,
      );
    }
  }

  Future<MoldAssessment?> getById(String id) async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .eq('id', id)
          .is_('deleted_at', null)
          .maybeSingle();

      if (response == null) return null;
      return MoldAssessment.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to load mold assessment',
        userMessage: 'Could not load assessment.',
        cause: e,
      );
    }
  }

  Future<List<MoldAssessment>> getByJob(String jobId) async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .eq('job_id', jobId)
          .is_('deleted_at', null)
          .order('created_at', ascending: false);

      return (response as List)
          .map((row) => MoldAssessment.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load mold assessments',
        userMessage: 'Could not load assessments.',
        cause: e,
      );
    }
  }

  Future<List<MoldAssessment>> getAll() async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .is_('deleted_at', null)
          .order('created_at', ascending: false);

      return (response as List)
          .map((row) => MoldAssessment.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load mold assessments',
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
        'Failed to delete mold assessment',
        userMessage: 'Could not delete assessment.',
        cause: e,
      );
    }
  }

  // ── Chain of Custody ──

  Future<Map<String, dynamic>> addSample(Map<String, dynamic> sample) async {
    try {
      final response = await supabase
          .from(_cocTable)
          .insert(sample)
          .select()
          .single();

      return response;
    } catch (e) {
      throw DatabaseError(
        'Failed to add sample',
        userMessage: 'Could not save sample.',
        cause: e,
      );
    }
  }

  Future<List<Map<String, dynamic>>> getSamples(String assessmentId) async {
    try {
      final response = await supabase
          .from(_cocTable)
          .select()
          .eq('mold_assessment_id', assessmentId)
          .order('created_at', ascending: false);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw DatabaseError(
        'Failed to load samples',
        userMessage: 'Could not load samples.',
        cause: e,
      );
    }
  }

  Future<void> updateSample(String sampleId, Map<String, dynamic> updates) async {
    try {
      await supabase.from(_cocTable).update(updates).eq('id', sampleId);
    } catch (e) {
      throw DatabaseError(
        'Failed to update sample',
        userMessage: 'Could not update sample.',
        cause: e,
      );
    }
  }

  // ── State Regulations ──

  Future<Map<String, dynamic>?> getStateRegulation(String stateCode) async {
    try {
      final response = await supabase
          .from('mold_state_regulations')
          .select()
          .eq('state_code', stateCode)
          .maybeSingle();

      return response;
    } catch (e) {
      throw DatabaseError(
        'Failed to load state regulation',
        userMessage: 'Could not load regulation.',
        cause: e,
      );
    }
  }

  Future<List<Map<String, dynamic>>> getAllStateRegulations() async {
    try {
      final response = await supabase
          .from('mold_state_regulations')
          .select()
          .order('state_code');

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw DatabaseError(
        'Failed to load state regulations',
        userMessage: 'Could not load regulations.',
        cause: e,
      );
    }
  }

  // ── Lab Directory ──

  Future<List<Map<String, dynamic>>> searchLabs({String? stateCode}) async {
    try {
      var query = supabase.from('mold_labs').select();
      if (stateCode != null) {
        query = query.eq('state_code', stateCode);
      }
      final response = await query.order('name');

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw DatabaseError(
        'Failed to search labs',
        userMessage: 'Could not load labs.',
        cause: e,
      );
    }
  }
}
