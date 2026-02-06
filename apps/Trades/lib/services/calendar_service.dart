/// ZAFTO Calendar Service
/// Sprint P0 - February 2026
/// Aggregates jobs into calendar view data

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/scheduled_item.dart';
import '../models/job.dart';
import 'job_service.dart';

// ============================================================
// PROVIDERS
// ============================================================

final calendarServiceProvider = Provider<CalendarService>((ref) {
  return CalendarService(ref);
});

/// Today's scheduled items for home screen RIGHT NOW section
final todayScheduleProvider = Provider<List<ScheduledItem>>((ref) {
  final service = ref.watch(calendarServiceProvider);
  final jobs = ref.watch(jobsProvider);

  return jobs.maybeWhen(
    data: (list) => service.getScheduleForDate(DateTime.now(), list),
    orElse: () => [],
  );
});

/// This week's schedule
final weekScheduleProvider = Provider<Map<DateTime, List<ScheduledItem>>>((ref) {
  final service = ref.watch(calendarServiceProvider);
  final jobs = ref.watch(jobsProvider);

  return jobs.maybeWhen(
    data: (list) => service.getWeekSchedule(DateTime.now(), list),
    orElse: () => {},
  );
});

/// Selected date's schedule (for calendar screen)
final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

final selectedDateScheduleProvider = Provider<List<ScheduledItem>>((ref) {
  final service = ref.watch(calendarServiceProvider);
  final jobs = ref.watch(jobsProvider);
  final selectedDate = ref.watch(selectedDateProvider);

  return jobs.maybeWhen(
    data: (list) => service.getScheduleForDate(selectedDate, list),
    orElse: () => [],
  );
});

/// Month stats for calendar dots
final monthStatsProvider = Provider.family<Map<DateTime, DayStats>, DateTime>((ref, month) {
  final service = ref.watch(calendarServiceProvider);
  final jobs = ref.watch(jobsProvider);

  return jobs.maybeWhen(
    data: (list) => service.getMonthStats(month, list),
    orElse: () => {},
  );
});

// ============================================================
// SERVICE
// ============================================================

class CalendarService {
  final Ref _ref;

  CalendarService(this._ref);

  /// Get all scheduled items for a specific date
  List<ScheduledItem> getScheduleForDate(DateTime date, List<Job> jobs) {
    final items = <ScheduledItem>[];

    // Convert jobs with scheduled dates to scheduled items
    for (final job in jobs) {
      if (job.scheduledStart != null && _isSameDay(job.scheduledStart!, date)) {
        items.add(ScheduledItem.fromJob(
          id: job.id,
          title: job.displayTitle,
          customerName: job.customerName,
          address: job.address,
          scheduledDate: job.scheduledStart!,
          notes: job.description,
        ));
      }
    }

    // Sort by start time
    items.sort((a, b) => a.start.compareTo(b.start));

    return items;
  }

  /// Get schedule for the current week (7 days starting from startOfWeek)
  Map<DateTime, List<ScheduledItem>> getWeekSchedule(DateTime referenceDate, List<Job> jobs) {
    final result = <DateTime, List<ScheduledItem>>{};

    // Get start of week (Monday)
    final startOfWeek = _getStartOfWeek(referenceDate);

    for (int i = 0; i < 7; i++) {
      final date = startOfWeek.add(Duration(days: i));
      final normalizedDate = DateTime(date.year, date.month, date.day);
      result[normalizedDate] = getScheduleForDate(normalizedDate, jobs);
    }

    return result;
  }

  /// Get stats for each day in a month (for showing dots on calendar)
  Map<DateTime, DayStats> getMonthStats(DateTime month, List<Job> jobs) {
    final result = <DateTime, DayStats>{};

    // Get all days in the month
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);

    for (var date = firstDay;
        date.isBefore(lastDay) || date.isAtSameMomentAs(lastDay);
        date = date.add(const Duration(days: 1))) {
      final normalizedDate = DateTime(date.year, date.month, date.day);
      final dayJobs = jobs.where((j) =>
          j.scheduledStart != null && _isSameDay(j.scheduledStart!, normalizedDate));

      if (dayJobs.isNotEmpty) {
        result[normalizedDate] = DayStats(
          date: normalizedDate,
          jobCount: dayJobs.length,
          totalRevenue: dayJobs.fold(0.0, (sum, j) => sum + (j.estimatedAmount)),
        );
      }
    }

    return result;
  }

  /// Get all scheduled items for a date range
  List<ScheduledItem> getScheduleForRange(
      DateTime start, DateTime end, List<Job> jobs) {
    final items = <ScheduledItem>[];

    for (final job in jobs) {
      if (job.scheduledStart != null) {
        final jobDate = job.scheduledStart!;
        if ((jobDate.isAfter(start) || _isSameDay(jobDate, start)) &&
            (jobDate.isBefore(end) || _isSameDay(jobDate, end))) {
          items.add(ScheduledItem.fromJob(
            id: job.id,
            title: job.displayTitle,
            customerName: job.customerName,
            address: job.address,
            scheduledDate: job.scheduledStart!,
            notes: job.description,
          ));
        }
      }
    }

    items.sort((a, b) => a.start.compareTo(b.start));
    return items;
  }

  /// Get upcoming items (next 7 days)
  List<ScheduledItem> getUpcoming(List<Job> jobs, {int days = 7}) {
    final now = DateTime.now();
    final end = now.add(Duration(days: days));
    return getScheduleForRange(now, end, jobs);
  }

  /// Get start of week (Monday)
  DateTime _getStartOfWeek(DateTime date) {
    final weekday = date.weekday; // Monday = 1, Sunday = 7
    return DateTime(date.year, date.month, date.day - (weekday - 1));
  }

  /// Check if two dates are the same day
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

// ============================================================
// HELPER EXTENSIONS
// ============================================================

extension DateTimeCalendarExtensions on DateTime {
  /// Get normalized date (midnight)
  DateTime get normalized => DateTime(year, month, day);

  /// Check if same day as another date
  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;

  /// Get day name abbreviation
  String get dayAbbreviation {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  /// Get month name
  String get monthName {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  /// Get short month name
  String get monthAbbreviation {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
}
