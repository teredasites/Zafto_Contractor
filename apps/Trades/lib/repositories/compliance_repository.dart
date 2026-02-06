// ZAFTO Compliance Repository — Supabase Backend
// CRUD for the compliance_records table.
// Records are INSERT-only (immutable audit trail — no update/delete RLS).

import '../core/supabase_client.dart';
import '../core/errors.dart';
import '../models/compliance_record.dart';

class ComplianceRepository {
  static const _table = 'compliance_records';

  // Create a new compliance record.
  Future<ComplianceRecord> createRecord(ComplianceRecord record) async {
    try {
      final response = await supabase
          .from(_table)
          .insert(record.toInsertJson())
          .select()
          .single();

      return ComplianceRecord.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to create ${record.recordType.label} record',
        userMessage: 'Could not save record. Please try again.',
        cause: e,
      );
    }
  }

  // Get all compliance records for a job.
  Future<List<ComplianceRecord>> getRecordsByJob(String jobId) async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .eq('job_id', jobId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((row) => ComplianceRecord.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load compliance records for job $jobId',
        userMessage: 'Could not load records.',
        cause: e,
      );
    }
  }

  // Get compliance records filtered by type.
  Future<List<ComplianceRecord>> getRecordsByType(
      ComplianceRecordType type) async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .eq('record_type', type.dbValue)
          .order('created_at', ascending: false);

      return (response as List)
          .map((row) => ComplianceRecord.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load ${type.label} records',
        userMessage: 'Could not load records.',
        cause: e,
      );
    }
  }

  // Get records for a job filtered by type.
  Future<List<ComplianceRecord>> getRecordsByJobAndType(
      String jobId, ComplianceRecordType type) async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .eq('job_id', jobId)
          .eq('record_type', type.dbValue)
          .order('created_at', ascending: false);

      return (response as List)
          .map((row) => ComplianceRecord.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load ${type.label} records for job $jobId',
        userMessage: 'Could not load records.',
        cause: e,
      );
    }
  }

  // Get recent records across all jobs (for dashboard/history views).
  Future<List<ComplianceRecord>> getRecentRecords({int limit = 50}) async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((row) => ComplianceRecord.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load recent compliance records',
        userMessage: 'Could not load records.',
        cause: e,
      );
    }
  }

  // Get a single record by ID.
  Future<ComplianceRecord?> getRecord(String id) async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return ComplianceRecord.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to load compliance record $id',
        userMessage: 'Could not load record.',
        cause: e,
      );
    }
  }
}
