// ZAFTO — Garage Door Service Repository
// Sprint NICHE2

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/garage_door_service.dart';
import '../core/errors.dart';

class GarageDoorServiceRepository {
  final SupabaseClient _client;
  GarageDoorServiceRepository(this._client);

  Future<List<GarageDoorService>> getAll() async {
    try {
      final res = await _client
          .from('garage_door_service_logs')
          .select()
          .is_('deleted_at', null)
          .order('created_at', ascending: false);
      return (res as List).map((e) => GarageDoorService.fromJson(e)).toList();
    } catch (e) {
      throw DatabaseError('Failed to fetch garage door logs: $e');
    }
  }

  Future<List<GarageDoorService>> getByJob(String jobId) async {
    try {
      final res = await _client
          .from('garage_door_service_logs')
          .select()
          .eq('job_id', jobId)
          .is_('deleted_at', null)
          .order('created_at', ascending: false);
      return (res as List).map((e) => GarageDoorService.fromJson(e)).toList();
    } catch (e) {
      throw DatabaseError('Failed to fetch garage door logs for job: $e');
    }
  }

  Future<List<GarageDoorService>> getByProperty(String propertyId) async {
    try {
      final res = await _client
          .from('garage_door_service_logs')
          .select()
          .eq('property_id', propertyId)
          .is_('deleted_at', null)
          .order('created_at', ascending: false);
      return (res as List).map((e) => GarageDoorService.fromJson(e)).toList();
    } catch (e) {
      throw DatabaseError('Failed to fetch garage door logs for property: $e');
    }
  }

  Future<GarageDoorService> create(Map<String, dynamic> data) async {
    try {
      final res = await _client
          .from('garage_door_service_logs')
          .insert(data)
          .select()
          .single();
      return GarageDoorService.fromJson(res);
    } catch (e) {
      throw DatabaseError('Failed to create garage door log: $e');
    }
  }

  Future<GarageDoorService> update(String id, Map<String, dynamic> data) async {
    try {
      final res = await _client
          .from('garage_door_service_logs')
          .update(data)
          .eq('id', id)
          .select()
          .single();
      return GarageDoorService.fromJson(res);
    } catch (e) {
      throw DatabaseError('Failed to update garage door log: $e');
    }
  }

  Future<void> softDelete(String id) async {
    try {
      await _client
          .from('garage_door_service_logs')
          .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', id);
    } catch (e) {
      throw DatabaseError('Failed to delete garage door log: $e');
    }
  }
}
