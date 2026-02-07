// ZAFTO Moisture Reading Repository — Supabase Backend
// CRUD for the moisture_readings table.

import '../core/supabase_client.dart';
import '../core/errors.dart';
import '../models/moisture_reading.dart';

class MoistureReadingRepository {
  static const _table = 'moisture_readings';

  Future<MoistureReading> createReading(MoistureReading reading) async {
    try {
      final response = await supabase
          .from(_table)
          .insert(reading.toInsertJson())
          .select()
          .single();

      return MoistureReading.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to save moisture reading',
        userMessage: 'Could not save reading. Please try again.',
        cause: e,
      );
    }
  }

  Future<List<MoistureReading>> getReadingsByJob(String jobId) async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .eq('job_id', jobId)
          .order('recorded_at', ascending: false);

      return (response as List)
          .map((row) => MoistureReading.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load moisture readings for job $jobId',
        userMessage: 'Could not load readings.',
        cause: e,
      );
    }
  }

  Future<List<MoistureReading>> getReadingsByClaim(String claimId) async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .eq('claim_id', claimId)
          .order('recorded_at', ascending: false);

      return (response as List)
          .map((row) => MoistureReading.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load moisture readings for claim $claimId',
        userMessage: 'Could not load readings.',
        cause: e,
      );
    }
  }

  Future<List<MoistureReading>> getReadingsByArea(
      String jobId, String areaName) async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .eq('job_id', jobId)
          .eq('area_name', areaName)
          .order('recorded_at', ascending: true);

      return (response as List)
          .map((row) => MoistureReading.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
        'Failed to load readings for area $areaName',
        userMessage: 'Could not load readings.',
        cause: e,
      );
    }
  }

  Future<List<String>> getAreas(String jobId) async {
    try {
      final response = await supabase
          .from(_table)
          .select('area_name')
          .eq('job_id', jobId)
          .order('area_name');

      final areas = (response as List)
          .map((row) => row['area_name'] as String)
          .toSet()
          .toList();
      return areas;
    } catch (e) {
      throw DatabaseError(
        'Failed to load areas',
        userMessage: 'Could not load areas.',
        cause: e,
      );
    }
  }

  Future<void> deleteReading(String id) async {
    try {
      await supabase.from(_table).delete().eq('id', id);
    } catch (e) {
      throw DatabaseError(
        'Failed to delete reading',
        userMessage: 'Could not delete reading.',
        cause: e,
      );
    }
  }
}
