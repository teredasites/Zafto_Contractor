// ZAFTO — Appliance Service Repository
// Sprint NICHE2

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/appliance_service.dart';
import '../core/errors.dart';

class ApplianceServiceRepository {
  final SupabaseClient _client;
  ApplianceServiceRepository(this._client);

  Future<List<ApplianceService>> getAll() async {
    try {
      final res = await _client
          .from('appliance_service_logs')
          .select()
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false);
      return (res as List).map((e) => ApplianceService.fromJson(e)).toList();
    } catch (e) {
      throw DatabaseError('Failed to fetch appliance logs: $e');
    }
  }

  Future<List<ApplianceService>> getByJob(String jobId) async {
    try {
      final res = await _client
          .from('appliance_service_logs')
          .select()
          .eq('job_id', jobId)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false);
      return (res as List).map((e) => ApplianceService.fromJson(e)).toList();
    } catch (e) {
      throw DatabaseError('Failed to fetch appliance logs for job: $e');
    }
  }

  Future<List<ApplianceService>> getByProperty(String propertyId) async {
    try {
      final res = await _client
          .from('appliance_service_logs')
          .select()
          .eq('property_id', propertyId)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false);
      return (res as List).map((e) => ApplianceService.fromJson(e)).toList();
    } catch (e) {
      throw DatabaseError('Failed to fetch appliance logs for property: $e');
    }
  }

  Future<ApplianceService> create(Map<String, dynamic> data) async {
    try {
      final res = await _client
          .from('appliance_service_logs')
          .insert(data)
          .select()
          .single();
      return ApplianceService.fromJson(res);
    } catch (e) {
      throw DatabaseError('Failed to create appliance log: $e');
    }
  }

  Future<ApplianceService> update(String id, Map<String, dynamic> data) async {
    try {
      final res = await _client
          .from('appliance_service_logs')
          .update(data)
          .eq('id', id)
          .select()
          .single();
      return ApplianceService.fromJson(res);
    } catch (e) {
      throw DatabaseError('Failed to update appliance log: $e');
    }
  }

  Future<void> softDelete(String id) async {
    try {
      await _client
          .from('appliance_service_logs')
          .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', id);
    } catch (e) {
      throw DatabaseError('Failed to delete appliance log: $e');
    }
  }
}
