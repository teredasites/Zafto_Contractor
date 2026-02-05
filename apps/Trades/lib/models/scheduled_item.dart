/// ZAFTO Scheduled Item Model
/// Sprint P0 - February 2026
/// Unified calendar event model for jobs, appointments, and reminders

import 'package:flutter/material.dart';

/// Type of scheduled item
enum ScheduledItemType {
  job,
  appointment,
  reminder,
  deadline,
}

/// A single item on the calendar
class ScheduledItem {
  final String id;
  final ScheduledItemType type;
  final String? jobId;
  final String title;
  final String? subtitle;
  final String? customerName;
  final String? address;
  final DateTime start;
  final DateTime? end;
  final int? durationMinutes;
  final Color color;
  final bool isAllDay;
  final String? notes;

  const ScheduledItem({
    required this.id,
    required this.type,
    this.jobId,
    required this.title,
    this.subtitle,
    this.customerName,
    this.address,
    required this.start,
    this.end,
    this.durationMinutes,
    this.color = const Color(0xFFFF9500),
    this.isAllDay = false,
    this.notes,
  });

  /// Create from a Job
  factory ScheduledItem.fromJob({
    required String id,
    required String title,
    String? customerName,
    String? address,
    required DateTime scheduledDate,
    int? durationMinutes,
    String? notes,
  }) {
    return ScheduledItem(
      id: 'schedule_$id',
      type: ScheduledItemType.job,
      jobId: id,
      title: title,
      subtitle: customerName,
      customerName: customerName,
      address: address,
      start: scheduledDate,
      durationMinutes: durationMinutes,
      color: const Color(0xFF34C759), // Green for jobs
      notes: notes,
    );
  }

  /// Duration display (e.g., "2h 30m")
  String get durationDisplay {
    if (durationMinutes == null) return '';
    final hours = durationMinutes! ~/ 60;
    final minutes = durationMinutes! % 60;
    if (hours > 0 && minutes > 0) return '${hours}h ${minutes}m';
    if (hours > 0) return '${hours}h';
    return '${minutes}m';
  }

  /// Time display (e.g., "9:00 AM")
  String get timeDisplay {
    final hour = start.hour > 12 ? start.hour - 12 : (start.hour == 0 ? 12 : start.hour);
    final period = start.hour >= 12 ? 'PM' : 'AM';
    final minute = start.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  /// Check if this item is today
  bool get isToday {
    final now = DateTime.now();
    return start.year == now.year && start.month == now.month && start.day == now.day;
  }

  /// Check if this item is in the past
  bool get isPast => start.isBefore(DateTime.now());

  ScheduledItem copyWith({
    String? id,
    ScheduledItemType? type,
    String? jobId,
    String? title,
    String? subtitle,
    String? customerName,
    String? address,
    DateTime? start,
    DateTime? end,
    int? durationMinutes,
    Color? color,
    bool? isAllDay,
    String? notes,
  }) {
    return ScheduledItem(
      id: id ?? this.id,
      type: type ?? this.type,
      jobId: jobId ?? this.jobId,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      customerName: customerName ?? this.customerName,
      address: address ?? this.address,
      start: start ?? this.start,
      end: end ?? this.end,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      color: color ?? this.color,
      isAllDay: isAllDay ?? this.isAllDay,
      notes: notes ?? this.notes,
    );
  }
}

/// Stats for a day on the calendar
class DayStats {
  final DateTime date;
  final int jobCount;
  final double totalRevenue;

  const DayStats({
    required this.date,
    this.jobCount = 0,
    this.totalRevenue = 0,
  });

  bool get hasItems => jobCount > 0;
}
