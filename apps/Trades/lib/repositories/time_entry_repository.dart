// ZAFTO Time Entry Repository — Supabase CRUD
// Created: Sprint B1e (Session 43)

import '../core/errors.dart';
import '../core/supabase_client.dart';
import '../models/time_entry.dart';

class TimeEntryRepository {
  // ==================== READ ====================

  Future<List<ClockEntry>> getEntries() async {
    try {
      final response = await supabase
          .from('time_entries')
          .select()
          .order('clock_in', ascending: false);
      return (response as List)
          .map((row) => ClockEntry.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError('Failed to fetch time entries: $e', cause: e);
    }
  }

  Future<ClockEntry?> getEntry(String id) async {
    try {
      final response =
          await supabase.from('time_entries').select().eq('id', id).maybeSingle();
      if (response == null) return null;
      return ClockEntry.fromJson(response);
    } catch (e) {
      throw DatabaseError('Failed to fetch time entry: $e', cause: e);
    }
  }

  /// Get active entry for a user (clock_out IS NULL, status = 'active')
  Future<ClockEntry?> getActiveEntry(String userId) async {
    try {
      final response = await supabase
          .from('time_entries')
          .select()
          .eq('user_id', userId)
          .isFilter('clock_out', null)
          .eq('status', 'active')
          .maybeSingle();
      if (response == null) return null;
      return ClockEntry.fromJson(response);
    } catch (e) {
      throw DatabaseError('Failed to fetch active entry: $e', cause: e);
    }
  }

  /// Get entries for a specific user
  Future<List<ClockEntry>> getEntriesForUser(String userId) async {
    try {
      final response = await supabase
          .from('time_entries')
          .select()
          .eq('user_id', userId)
          .order('clock_in', ascending: false);
      return (response as List)
          .map((row) => ClockEntry.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError('Failed to fetch user entries: $e', cause: e);
    }
  }

  /// Get entries for a specific job
  Future<List<ClockEntry>> getEntriesForJob(String jobId) async {
    try {
      final response = await supabase
          .from('time_entries')
          .select()
          .eq('job_id', jobId)
          .order('clock_in', ascending: false);
      return (response as List)
          .map((row) => ClockEntry.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError('Failed to fetch job entries: $e', cause: e);
    }
  }

  /// Get entries within a date range
  Future<List<ClockEntry>> getEntriesForRange(
      DateTime start, DateTime end) async {
    try {
      final response = await supabase
          .from('time_entries')
          .select()
          .gte('clock_in', start.toIso8601String())
          .lte('clock_in', end.toIso8601String())
          .order('clock_in', ascending: false);
      return (response as List)
          .map((row) => ClockEntry.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError('Failed to fetch entries for range: $e', cause: e);
    }
  }

  /// Get currently clocked-in entries (all users, for dashboard)
  Future<List<ClockEntry>> getClockedInEntries() async {
    try {
      final response = await supabase
          .from('time_entries')
          .select()
          .isFilter('clock_out', null)
          .eq('status', 'active')
          .order('clock_in', ascending: false);
      return (response as List)
          .map((row) => ClockEntry.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError('Failed to fetch clocked-in entries: $e', cause: e);
    }
  }

  /// Get entries by status (for approval workflow)
  Future<List<ClockEntry>> getEntriesByStatus(ClockEntryStatus status) async {
    try {
      final response = await supabase
          .from('time_entries')
          .select()
          .eq('status', status.name)
          .order('clock_in', ascending: false);
      return (response as List)
          .map((row) => ClockEntry.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError('Failed to fetch entries by status: $e', cause: e);
    }
  }

  // ==================== WRITE ====================

  Future<ClockEntry> createEntry(ClockEntry entry) async {
    try {
      final response = await supabase
          .from('time_entries')
          .insert(entry.toInsertJson())
          .select()
          .single();
      return ClockEntry.fromJson(response);
    } catch (e) {
      throw DatabaseError('Failed to create time entry: $e', cause: e);
    }
  }

  Future<ClockEntry> updateEntry(ClockEntry entry) async {
    try {
      final response = await supabase
          .from('time_entries')
          .update(entry.toUpdateJson())
          .eq('id', entry.id)
          .select()
          .single();
      return ClockEntry.fromJson(response);
    } catch (e) {
      throw DatabaseError('Failed to update time entry: $e', cause: e);
    }
  }

  /// Clock out an entry (set clock_out, calculate totals)
  Future<ClockEntry> clockOut(String entryId, ClockEntry updated) async {
    try {
      final response = await supabase
          .from('time_entries')
          .update(updated.toUpdateJson())
          .eq('id', entryId)
          .select()
          .single();
      return ClockEntry.fromJson(response);
    } catch (e) {
      throw DatabaseError('Failed to clock out: $e', cause: e);
    }
  }

  /// Update entry status (approve/reject)
  Future<ClockEntry> updateStatus(
    String entryId, {
    required ClockEntryStatus status,
    String? approvedBy,
  }) async {
    try {
      final data = <String, dynamic>{
        'status': status.name,
      };
      if (approvedBy != null) {
        data['approved_by'] = approvedBy;
        data['approved_at'] = DateTime.now().toIso8601String();
      }
      final response = await supabase
          .from('time_entries')
          .update(data)
          .eq('id', entryId)
          .select()
          .single();
      return ClockEntry.fromJson(response);
    } catch (e) {
      throw DatabaseError('Failed to update entry status: $e', cause: e);
    }
  }

  /// Update location pings (append new pings during active tracking)
  Future<void> updateLocationPings(
      String entryId, Map<String, dynamic> pingsPayload) async {
    try {
      await supabase
          .from('time_entries')
          .update({'location_pings': pingsPayload})
          .eq('id', entryId);
    } catch (e) {
      throw DatabaseError('Failed to update location pings: $e', cause: e);
    }
  }

  Future<void> deleteEntry(String id) async {
    try {
      await supabase.from('time_entries').delete().eq('id', id);
    } catch (e) {
      throw DatabaseError('Failed to delete time entry: $e', cause: e);
    }
  }
}
