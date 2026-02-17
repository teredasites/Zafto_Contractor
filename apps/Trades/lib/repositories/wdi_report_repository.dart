// ZAFTO WDI Report Repository — Supabase Backend
// CRUD for wdi_reports table. Sprint NICHE1 — Pest control module.

import '../core/supabase_client.dart';
import '../core/errors.dart';
import '../models/wdi_report.dart';

class WdiReportRepository {
  static const _table = 'wdi_reports';

  Future<WdiReport> create(WdiReport report) async {
    try {
      final response = await supabase
          .from(_table)
          .insert(report.toInsertJson())
          .select()
          .single();
      return WdiReport.fromJson(response);
    } catch (e) {
      throw DatabaseError('Failed to create WDI report',
          userMessage: 'Could not save WDI report.', cause: e);
    }
  }

  Future<WdiReport> update(String id, Map<String, dynamic> updates) async {
    try {
      final response = await supabase
          .from(_table)
          .update(updates)
          .eq('id', id)
          .select()
          .single();
      return WdiReport.fromJson(response);
    } catch (e) {
      throw DatabaseError('Failed to update WDI report',
          userMessage: 'Could not update WDI report.', cause: e);
    }
  }

  Future<WdiReport?> getById(String id) async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .eq('id', id)
          .is_('deleted_at', null)
          .maybeSingle();
      if (response == null) return null;
      return WdiReport.fromJson(response);
    } catch (e) {
      throw DatabaseError('Failed to load WDI report',
          userMessage: 'Could not load WDI report.', cause: e);
    }
  }

  Future<List<WdiReport>> getByJob(String jobId) async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .eq('job_id', jobId)
          .is_('deleted_at', null)
          .order('created_at', ascending: false);
      return (response as List).map((r) => WdiReport.fromJson(r)).toList();
    } catch (e) {
      throw DatabaseError('Failed to load WDI reports',
          userMessage: 'Could not load WDI reports.', cause: e);
    }
  }

  Future<List<WdiReport>> getAll() async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .is_('deleted_at', null)
          .order('created_at', ascending: false);
      return (response as List).map((r) => WdiReport.fromJson(r)).toList();
    } catch (e) {
      throw DatabaseError('Failed to load WDI reports',
          userMessage: 'Could not load WDI reports.', cause: e);
    }
  }

  Future<void> softDelete(String id) async {
    try {
      await supabase.from(_table).update(
        {'deleted_at': DateTime.now().toUtc().toIso8601String()},
      ).eq('id', id);
    } catch (e) {
      throw DatabaseError('Failed to delete WDI report',
          userMessage: 'Could not delete WDI report.', cause: e);
    }
  }
}
