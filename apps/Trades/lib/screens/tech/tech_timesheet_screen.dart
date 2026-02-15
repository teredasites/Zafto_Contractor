import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

import 'package:zafto/theme/theme_provider.dart';
import 'package:zafto/theme/zafto_colors.dart';
import 'package:zafto/models/time_entry.dart';
import 'package:zafto/services/time_clock_service.dart';
import 'package:zafto/widgets/shared/matrix_rain_painter.dart';

// ============================================================
// Tech Timesheet Screen — Weekly hours, daily breakdown
//
// Shows the tech's time entries for the selected week with
// daily totals, break tracking, and weekly summary.
// Accessible from "My Hours" tile on tech home + More menu.
// ============================================================

class TechTimesheetScreen extends ConsumerStatefulWidget {
  const TechTimesheetScreen({super.key});

  @override
  ConsumerState<TechTimesheetScreen> createState() => _TechTimesheetScreenState();
}

class _TechTimesheetScreenState extends ConsumerState<TechTimesheetScreen> {
  late DateTime _weekStart;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _weekStart = now.subtract(Duration(days: now.weekday - 1));
    _weekStart = DateTime(_weekStart.year, _weekStart.month, _weekStart.day);
  }

  void _previousWeek() {
    setState(() => _weekStart = _weekStart.subtract(const Duration(days: 7)));
  }

  void _nextWeek() {
    final now = DateTime.now();
    final nextWeekStart = _weekStart.add(const Duration(days: 7));
    if (nextWeekStart.isBefore(DateTime(now.year, now.month, now.day + 1))) {
      setState(() => _weekStart = nextWeekStart);
    }
  }

  // Compute weekly stats from raw time entries
  _WeeklyStats _computeStats(List<ClockEntry> allEntries) {
    final weekEnd = _weekStart.add(const Duration(days: 7));
    final weekEntries = allEntries.where((e) {
      return e.clockIn.isAfter(_weekStart) && e.clockIn.isBefore(weekEnd);
    }).toList();

    final dailyHours = List<double>.filled(7, 0.0);
    final dailyBreaks = List<double>.filled(7, 0.0);
    double totalHours = 0;
    double totalBreaks = 0;
    final daysWithWork = <int>{};

    for (final entry in weekEntries) {
      final dayIndex = entry.clockIn.weekday - 1; // Mon=0, Sun=6
      if (dayIndex < 0 || dayIndex > 6) continue;

      final worked = entry.workedTime;
      final hours = worked.inMinutes / 60.0;
      dailyHours[dayIndex] += hours;
      totalHours += hours;
      daysWithWork.add(dayIndex);

      final breakTime = entry.totalBreakTime;
      final breakHours = breakTime.inMinutes / 60.0;
      dailyBreaks[dayIndex] += breakHours;
      totalBreaks += breakHours;
    }

    final overtime = (totalHours - 40).clamp(0.0, double.infinity);

    return _WeeklyStats(
      totalHours: totalHours,
      overtimeHours: overtime,
      breakHours: totalBreaks,
      daysWorked: daysWithWork.length,
      dailyHours: dailyHours,
      entries: weekEntries,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    final entriesAsync = ref.watch(userTimeEntriesProvider);
    final weekEnd = _weekStart.add(const Duration(days: 6));
    final dateFormat = DateFormat('MMM d');

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My Timesheet',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: colors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: entriesAsync.when(
          loading: () => Center(child: CircularProgressIndicator(color: colors.accentPrimary)),
          error: (e, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.alertCircle, size: 40, color: colors.accentWarning),
                const SizedBox(height: 12),
                Text('Failed to load time entries', style: TextStyle(color: colors.textSecondary)),
              ],
            ),
          ),
          data: (entries) {
            final stats = _computeStats(entries);
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  _buildWeekNavigator(colors, dateFormat, weekEnd),
                  const SizedBox(height: 20),
                  _buildWeeklySummary(colors, stats),
                  const SizedBox(height: 20),
                  _buildDailyBreakdown(colors, stats),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Week Navigator ────────────────────────────────────────
  Widget _buildWeekNavigator(ZaftoColors colors, DateFormat fmt, DateTime weekEnd) {
    final now = DateTime.now();
    final isCurrentWeek = _weekStart.isBefore(now) &&
        weekEnd.add(const Duration(days: 1)).isAfter(now);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _previousWeek,
            icon: Icon(LucideIcons.chevronLeft, size: 18, color: colors.textSecondary),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
          const Spacer(),
          Column(
            children: [
              Text(
                '${fmt.format(_weekStart)} - ${fmt.format(weekEnd)}',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colors.textPrimary),
              ),
              if (isCurrentWeek)
                Text('This Week', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: crmEmerald)),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: _nextWeek,
            icon: Icon(LucideIcons.chevronRight, size: 18, color: colors.textSecondary),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  // ── Weekly Summary ────────────────────────────────────────
  Widget _buildWeeklySummary(ZaftoColors colors, _WeeklyStats stats) {
    final regularHours = (stats.totalHours - stats.overtimeHours).clamp(0.0, double.infinity);
    final progressPct = (stats.totalHours / 40).clamp(0.0, 1.0);
    final isOvertime = stats.totalHours > 40;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOvertime ? colors.accentWarning.withValues(alpha: 0.5) : colors.borderSubtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                stats.totalHours.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  color: isOvertime ? colors.accentWarning : colors.textPrimary,
                  height: 1,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('/ 40 hrs', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: colors.textTertiary)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progressPct,
              backgroundColor: colors.fillDefault,
              valueColor: AlwaysStoppedAnimation(isOvertime ? colors.accentWarning : crmEmerald),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStat(colors, 'Regular', '${regularHours.toStringAsFixed(1)}h', colors.accentSuccess),
              Container(width: 1, height: 28, color: colors.borderSubtle),
              _buildStat(colors, 'Overtime', '${stats.overtimeHours.toStringAsFixed(1)}h', colors.accentWarning),
              Container(width: 1, height: 28, color: colors.borderSubtle),
              _buildStat(colors, 'Breaks', '${stats.breakHours.toStringAsFixed(1)}h', colors.accentInfo),
              Container(width: 1, height: 28, color: colors.borderSubtle),
              _buildStat(colors, 'Days', '${stats.daysWorked}', colors.textSecondary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(ZaftoColors colors, String label, String value, Color valueColor) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: valueColor)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: colors.textTertiary)),
        ],
      ),
    );
  }

  // ── Daily Breakdown ───────────────────────────────────────
  Widget _buildDailyBreakdown(ZaftoColors colors, _WeeklyStats stats) {
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final now = DateTime.now();
    final dayFormat = DateFormat('MMM d');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            'DAILY BREAKDOWN',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.0, color: colors.textTertiary),
          ),
        ),
        ...List.generate(7, (i) {
          final day = _weekStart.add(Duration(days: i));
          final isToday = day.year == now.year && day.month == now.month && day.day == now.day;
          final isFuture = day.isAfter(now);
          final hours = stats.dailyHours[i];

          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isToday ? crmEmerald.withValues(alpha: 0.08) : colors.bgElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isToday ? crmEmerald.withValues(alpha: 0.3) : colors.borderSubtle,
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 36,
                  child: Text(
                    dayNames[i],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isToday ? crmEmerald : (isFuture ? colors.textQuaternary : colors.textSecondary),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  dayFormat.format(day),
                  style: TextStyle(fontSize: 12, color: isFuture ? colors.textQuaternary : colors.textTertiary),
                ),
                const Spacer(),
                if (isToday && hours > 0)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(color: crmEmerald, shape: BoxShape.circle),
                  ),
                Text(
                  isFuture ? '--' : '${hours.toStringAsFixed(1)}h',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isFuture ? colors.textQuaternary : (hours > 0 ? colors.textPrimary : colors.textTertiary),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

// ── Internal Stats Model ──────────────────────────────────
class _WeeklyStats {
  final double totalHours;
  final double overtimeHours;
  final double breakHours;
  final int daysWorked;
  final List<double> dailyHours;
  final List<ClockEntry> entries;

  const _WeeklyStats({
    required this.totalHours,
    required this.overtimeHours,
    required this.breakHours,
    required this.daysWorked,
    required this.dailyHours,
    required this.entries,
  });
}
