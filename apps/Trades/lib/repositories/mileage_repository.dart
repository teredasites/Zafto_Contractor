// ZAFTO Mileage Repository — Supabase Backend
// CRUD for the mileage_trips table.

import '../core/supabase_client.dart';
import '../core/errors.dart';
import '../models/mileage_trip.dart';

class MileageRepository {
  static const _table = 'mileage_trips';

  // Create a new mileage trip.
  Future<MileageTrip> createTrip(MileageTrip trip) async {
    try {
      final response = await supabase
          .from(_table)
          .insert(trip.toInsertJson())
          .select()
          .single();

      return MileageTrip.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to save mileage trip',
        userMessage: 'Could not save trip. Please try again.',
        cause: e,
      );
    }
  }

  // Get all trips for a user.
  Future<List<MileageTrip>> getTripsByUser({int limit = 100}) async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .isFilter('deleted_at', null)
          .order('trip_date', ascending: false)
          .limit(limit);

      return (response as List)
          .map((row) => MileageTrip.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load mileage trips',
        userMessage: 'Could not load trips.',
        cause: e,
      );
    }
  }

  // Get trips for a specific job.
  Future<List<MileageTrip>> getTripsByJob(String jobId) async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .eq('job_id', jobId)
          .isFilter('deleted_at', null)
          .order('trip_date', ascending: false);

      return (response as List)
          .map((row) => MileageTrip.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load trips for job $jobId',
        userMessage: 'Could not load trips.',
        cause: e,
      );
    }
  }

  // Get trips in a date range (for reports).
  Future<List<MileageTrip>> getTripsByDateRange(
      DateTime start, DateTime end) async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .gte('trip_date', start.toUtc().toIso8601String())
          .lte('trip_date', end.toUtc().toIso8601String())
          .isFilter('deleted_at', null)
          .order('trip_date', ascending: false);

      return (response as List)
          .map((row) => MileageTrip.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load trips for date range',
        userMessage: 'Could not load trips.',
        cause: e,
      );
    }
  }

  // Update trip (e.g., add purpose after stop).
  Future<MileageTrip> updateTrip(String id, Map<String, dynamic> updates) async {
    try {
      final response = await supabase
          .from(_table)
          .update(updates)
          .eq('id', id)
          .select()
          .single();

      return MileageTrip.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to update trip $id',
        userMessage: 'Could not update trip.',
        cause: e,
      );
    }
  }

  // Soft delete.
  Future<void> deleteTrip(String id) async {
    try {
      await supabase
          .from(_table)
          .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', id);
    } catch (e) {
      throw DatabaseError(
        'Failed to delete trip $id',
        userMessage: 'Could not delete trip.',
        cause: e,
      );
    }
  }
}
