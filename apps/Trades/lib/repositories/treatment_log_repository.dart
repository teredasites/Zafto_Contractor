// ZAFTO Treatment Log Repository — Supabase Backend
// CRUD for treatment_logs table. Sprint NICHE1 — Pest control module.

import '../core/supabase_client.dart';
import '../core/errors.dart';
import '../models/treatment_log.dart';

class TreatmentLogRepository {
  static const _table = 'treatment_logs';

  Future<TreatmentLog> create(TreatmentLog log) async {
    try {
      final response = await supabase
          .from(_table)
          .insert(log.toInsertJson())
          .select()
          .single();
      return TreatmentLog.fromJson(response);
    } catch (e) {
      throw DatabaseError('Failed to create treatment log',
          userMessage: 'Could not save treatment log.', cause: e);
    }
  }

  Future<TreatmentLog> update(String id, Map<String, dynamic> updates) async {
    try {
      final response = await supabase
          .from(_table)
          .update(updates)
          .eq('id', id)
          .select()
          .single();
      return TreatmentLog.fromJson(response);
    } catch (e) {
      throw DatabaseError('Failed to update treatment log',
          userMessage: 'Could not update treatment log.', cause: e);
    }
  }

  Future<TreatmentLog?> getById(String id) async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .eq('id', id)
          .is_('deleted_at', null)
          .maybeSingle();
      if (response == null) return null;
      return TreatmentLog.fromJson(response);
    } catch (e) {
      throw DatabaseError('Failed to load treatment log',
          userMessage: 'Could not load treatment log.', cause: e);
    }
  }

  Future<List<TreatmentLog>> getByJob(String jobId) async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .eq('job_id', jobId)
          .is_('deleted_at', null)
          .order('created_at', ascending: false);
      return (response as List).map((r) => TreatmentLog.fromJson(r)).toList();
    } catch (e) {
      throw DatabaseError('Failed to load treatment logs',
          userMessage: 'Could not load treatment logs.', cause: e);
    }
  }

  Future<List<TreatmentLog>> getByProperty(String propertyId) async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .eq('property_id', propertyId)
          .is_('deleted_at', null)
          .order('created_at', ascending: false);
      return (response as List).map((r) => TreatmentLog.fromJson(r)).toList();
    } catch (e) {
      throw DatabaseError('Failed to load treatment logs',
          userMessage: 'Could not load treatment logs.', cause: e);
    }
  }

  Future<List<TreatmentLog>> getAll() async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .is_('deleted_at', null)
          .order('created_at', ascending: false);
      return (response as List).map((r) => TreatmentLog.fromJson(r)).toList();
    } catch (e) {
      throw DatabaseError('Failed to load treatment logs',
          userMessage: 'Could not load treatment logs.', cause: e);
    }
  }

  Future<List<TreatmentLog>> getUpcomingServices() async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .is_('deleted_at', null)
          .not('next_service_date', 'is', null)
          .gte('next_service_date', DateTime.now().toIso8601String().split('T')[0])
          .order('next_service_date');
      return (response as List).map((r) => TreatmentLog.fromJson(r)).toList();
    } catch (e) {
      throw DatabaseError('Failed to load upcoming services',
          userMessage: 'Could not load upcoming services.', cause: e);
    }
  }

  Future<void> softDelete(String id) async {
    try {
      await supabase.from(_table).update(
        {'deleted_at': DateTime.now().toUtc().toIso8601String()},
      ).eq('id', id);
    } catch (e) {
      throw DatabaseError('Failed to delete treatment log',
          userMessage: 'Could not delete treatment log.', cause: e);
    }
  }
}
