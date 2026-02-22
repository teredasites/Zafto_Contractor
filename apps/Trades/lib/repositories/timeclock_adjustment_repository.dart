import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/timeclock_adjustment.dart';

class TimeclockAdjustmentRepository {
  final SupabaseClient _client;

  TimeclockAdjustmentRepository(this._client);

  /// Fetch adjustment history for a specific time entry.
  Future<List<TimeclockAdjustment>> getByTimeEntry(String timeEntryId) async {
    final res = await _client
        .from('timeclock_adjustments')
        .select()
        .eq('time_entry_id', timeEntryId)
        .order('created_at', ascending: false);
    return (res as List).map((e) =>
        TimeclockAdjustment.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Fetch all adjustments for an employee (visible in their time history).
  Future<List<TimeclockAdjustment>> getByEmployee(
    String companyId,
    String employeeId, {
    DateTime? from,
    DateTime? to,
  }) async {
    var query = _client
        .from('timeclock_adjustments')
        .select()
        .eq('company_id', companyId)
        .eq('employee_id', employeeId);

    if (from != null) {
      query = query.gte('created_at', from.toIso8601String());
    }
    if (to != null) {
      query = query.lte('created_at', to.toIso8601String());
    }

    final res = await query.order('created_at', ascending: false);
    return (res as List).map((e) =>
        TimeclockAdjustment.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Fetch all adjustments made by a specific manager.
  Future<List<TimeclockAdjustment>> getByAdjuster(
    String companyId,
    String adjustedByUserId, {
    int limit = 50,
  }) async {
    final res = await _client
        .from('timeclock_adjustments')
        .select()
        .eq('company_id', companyId)
        .eq('adjusted_by', adjustedByUserId)
        .order('created_at', ascending: false)
        .limit(limit);
    return (res as List).map((e) =>
        TimeclockAdjustment.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Create a time clock adjustment.
  /// This also updates the time_entries row with the new values.
  Future<TimeclockAdjustment> adjustTimeEntry({
    required String companyId,
    required String timeEntryId,
    required String adjustedByUserId,
    required String employeeId,
    required DateTime originalClockIn,
    DateTime? originalClockOut,
    int? originalBreakMinutes,
    required DateTime adjustedClockIn,
    DateTime? adjustedClockOut,
    int? adjustedBreakMinutes,
    required String reason,
    String adjustmentType = 'manual',
  }) async {
    // 1. Insert the adjustment audit record
    final adjRes = await _client.from('timeclock_adjustments').insert({
      'company_id': companyId,
      'time_entry_id': timeEntryId,
      'adjusted_by': adjustedByUserId,
      'employee_id': employeeId,
      'original_clock_in': originalClockIn.toIso8601String(),
      'original_clock_out': originalClockOut?.toIso8601String(),
      'original_break_minutes': originalBreakMinutes,
      'adjusted_clock_in': adjustedClockIn.toIso8601String(),
      'adjusted_clock_out': adjustedClockOut?.toIso8601String(),
      'adjusted_break_minutes': adjustedBreakMinutes,
      'reason': reason,
      'adjustment_type': adjustmentType,
    }).select().single();

    // 2. Update the time entry with adjusted values
    final updateData = <String, dynamic>{
      'clock_in': adjustedClockIn.toIso8601String(),
      'last_adjusted_at': DateTime.now().toIso8601String(),
      'last_adjusted_by': adjustedByUserId,
    };
    if (adjustedClockOut != null) {
      updateData['clock_out'] = adjustedClockOut.toIso8601String();
    }
    if (adjustedBreakMinutes != null) {
      updateData['break_minutes'] = adjustedBreakMinutes;
    }

    // Recalculate total_minutes if both clock_in and clock_out are set
    if (adjustedClockOut != null) {
      final totalMins =
          adjustedClockOut.difference(adjustedClockIn).inMinutes -
              (adjustedBreakMinutes ?? 0);
      updateData['total_minutes'] = totalMins > 0 ? totalMins : 0;
    }

    await _client
        .from('time_entries')
        .update(updateData)
        .eq('id', timeEntryId);

    return TimeclockAdjustment.fromJson(adjRes);
  }

  /// Mark an adjustment as acknowledged by the employee.
  Future<void> acknowledgeAdjustment(String adjustmentId) async {
    await _client.from('timeclock_adjustments').update({
      'employee_acknowledged_at': DateTime.now().toIso8601String(),
    }).eq('id', adjustmentId);
  }
}
