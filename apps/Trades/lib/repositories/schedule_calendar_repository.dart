// ZAFTO Schedule Calendar Repository
// CRUD for schedule_calendars + schedule_calendar_exceptions tables.
// RLS handles company scoping.
// GC1: Phase GC foundation.

import '../core/errors.dart';
import '../core/supabase_client.dart';
import '../models/schedule_calendar.dart';
import '../models/schedule_calendar_exception.dart';

class ScheduleCalendarRepository {
  // =========================================================================
  // CALENDARS
  // =========================================================================

  Future<List<ScheduleCalendar>> getCalendars() async {
    try {
      final response = await supabase
          .from('schedule_calendars')
          .select()
          .isFilter('deleted_at', null)
          .order('is_default', ascending: false)
          .order('name', ascending: true);
      return (response as List)
          .map((row) =>
              ScheduleCalendar.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw DatabaseError('Failed to fetch calendars: $e', cause: e);
    }
  }

  Future<ScheduleCalendar?> getDefaultCalendar() async {
    try {
      final response = await supabase
          .from('schedule_calendars')
          .select()
          .eq('is_default', true)
          .isFilter('deleted_at', null)
          .limit(1)
          .maybeSingle();
      if (response == null) return null;
      return ScheduleCalendar.fromJson(response);
    } catch (e) {
      throw DatabaseError('Failed to fetch default calendar: $e', cause: e);
    }
  }

  Future<ScheduleCalendar> createCalendar(ScheduleCalendar calendar) async {
    try {
      final response = await supabase
          .from('schedule_calendars')
          .insert(calendar.toInsertJson())
          .select()
          .single();
      return ScheduleCalendar.fromJson(response);
    } catch (e) {
      throw DatabaseError('Failed to create calendar: $e', cause: e);
    }
  }

  Future<void> updateCalendar(
      String id, Map<String, dynamic> updates) async {
    try {
      await supabase.from('schedule_calendars').update(updates).eq('id', id);
    } catch (e) {
      throw DatabaseError('Failed to update calendar: $e', cause: e);
    }
  }

  Future<void> deleteCalendar(String id) async {
    try {
      await supabase.from('schedule_calendars').update({
        'deleted_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', id);
    } catch (e) {
      throw DatabaseError('Failed to delete calendar: $e', cause: e);
    }
  }

  /// Set a calendar as the default, unsetting any previous default.
  Future<void> setDefaultCalendar(String calendarId) async {
    try {
      // Unset previous defaults
      await supabase
          .from('schedule_calendars')
          .update({'is_default': false})
          .eq('is_default', true);
      // Set new default
      await supabase
          .from('schedule_calendars')
          .update({'is_default': true})
          .eq('id', calendarId);
    } catch (e) {
      throw DatabaseError('Failed to set default calendar: $e', cause: e);
    }
  }

  // =========================================================================
  // CALENDAR EXCEPTIONS
  // =========================================================================

  Future<List<ScheduleCalendarException>> getExceptions(
      String calendarId) async {
    try {
      final response = await supabase
          .from('schedule_calendar_exceptions')
          .select()
          .eq('calendar_id', calendarId)
          .order('exception_date', ascending: true);
      return (response as List)
          .map((row) => ScheduleCalendarException.fromJson(
              row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw DatabaseError('Failed to fetch calendar exceptions: $e', cause: e);
    }
  }

  Future<ScheduleCalendarException> createException(
      ScheduleCalendarException exception) async {
    try {
      final response = await supabase
          .from('schedule_calendar_exceptions')
          .insert(exception.toInsertJson())
          .select()
          .single();
      return ScheduleCalendarException.fromJson(response);
    } catch (e) {
      throw DatabaseError('Failed to create calendar exception: $e', cause: e);
    }
  }

  Future<void> deleteException(String id) async {
    try {
      await supabase
          .from('schedule_calendar_exceptions')
          .delete()
          .eq('id', id);
    } catch (e) {
      throw DatabaseError('Failed to delete calendar exception: $e', cause: e);
    }
  }
}
