// ZAFTO — Locksmith Service Repository
// Sprint NICHE2

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/locksmith_service.dart';
import '../core/errors.dart';

class LocksmithServiceRepository {
  final SupabaseClient _client;
  LocksmithServiceRepository(this._client);

  Future<List<LocksmithService>> getAll() async {
    try {
      final res = await _client
          .from('locksmith_service_logs')
          .select()
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false);
      return (res as List).map((e) => LocksmithService.fromJson(e)).toList();
    } catch (e) {
      throw DatabaseError('Failed to fetch locksmith logs: $e');
    }
  }

  Future<List<LocksmithService>> getByJob(String jobId) async {
    try {
      final res = await _client
          .from('locksmith_service_logs')
          .select()
          .eq('job_id', jobId)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false);
      return (res as List).map((e) => LocksmithService.fromJson(e)).toList();
    } catch (e) {
      throw DatabaseError('Failed to fetch locksmith logs for job: $e');
    }
  }

  Future<LocksmithService> create(Map<String, dynamic> data) async {
    try {
      final res = await _client
          .from('locksmith_service_logs')
          .insert(data)
          .select()
          .single();
      return LocksmithService.fromJson(res);
    } catch (e) {
      throw DatabaseError('Failed to create locksmith log: $e');
    }
  }

  Future<LocksmithService> update(String id, Map<String, dynamic> data) async {
    try {
      final res = await _client
          .from('locksmith_service_logs')
          .update(data)
          .eq('id', id)
          .select()
          .single();
      return LocksmithService.fromJson(res);
    } catch (e) {
      throw DatabaseError('Failed to update locksmith log: $e');
    }
  }

  Future<void> softDelete(String id) async {
    try {
      await _client
          .from('locksmith_service_logs')
          .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', id);
    } catch (e) {
      throw DatabaseError('Failed to delete locksmith log: $e');
    }
  }
}
