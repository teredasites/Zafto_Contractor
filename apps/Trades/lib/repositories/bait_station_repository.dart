// ZAFTO Bait Station Repository — Supabase Backend
// CRUD for bait_stations table. Sprint NICHE1 — Pest control module.

import '../core/supabase_client.dart';
import '../core/errors.dart';

class BaitStationRepository {
  static const _table = 'bait_stations';

  Future<Map<String, dynamic>> create(Map<String, dynamic> station) async {
    try {
      final response = await supabase
          .from(_table)
          .insert(station)
          .select()
          .single();
      return response;
    } catch (e) {
      throw DatabaseError('Failed to create bait station',
          userMessage: 'Could not save bait station.', cause: e);
    }
  }

  Future<Map<String, dynamic>> update(
      String id, Map<String, dynamic> updates) async {
    try {
      final response = await supabase
          .from(_table)
          .update(updates)
          .eq('id', id)
          .select()
          .single();
      return response;
    } catch (e) {
      throw DatabaseError('Failed to update bait station',
          userMessage: 'Could not update bait station.', cause: e);
    }
  }

  Future<List<Map<String, dynamic>>> getByProperty(String propertyId) async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .eq('property_id', propertyId)
          .is_('deleted_at', null)
          .order('station_number');
      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw DatabaseError('Failed to load bait stations',
          userMessage: 'Could not load bait stations.', cause: e);
    }
  }

  Future<List<Map<String, dynamic>>> getAll() async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .is_('deleted_at', null)
          .order('station_number');
      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw DatabaseError('Failed to load bait stations',
          userMessage: 'Could not load bait stations.', cause: e);
    }
  }

  Future<void> serviceStation(String id) async {
    try {
      await supabase.from(_table).update({
        'last_serviced_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', id);
    } catch (e) {
      throw DatabaseError('Failed to service station',
          userMessage: 'Could not update station.', cause: e);
    }
  }

  Future<void> softDelete(String id) async {
    try {
      await supabase.from(_table).update(
        {'deleted_at': DateTime.now().toUtc().toIso8601String()},
      ).eq('id', id);
    } catch (e) {
      throw DatabaseError('Failed to delete bait station',
          userMessage: 'Could not delete bait station.', cause: e);
    }
  }
}
