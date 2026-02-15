import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:zafto/theme/zafto_colors.dart';
import 'package:zafto/theme/theme_provider.dart';
import 'package:zafto/models/job.dart';
import 'package:zafto/services/job_service.dart';
import 'package:zafto/screens/jobs/job_detail_screen.dart';

// ============================================================
// Tech Schedule Screen — Read-Only Job Calendar
//
// Shows jobs assigned to this technician. Day + week view toggle.
// Tap a job → job detail (read-only). No editing, no reassigning.
// Real data from jobsProvider, filtered by scheduled date.
// ============================================================

class TechScheduleScreen extends ConsumerStatefulWidget {
  const TechScheduleScreen({super.key});

  @override
  ConsumerState<TechScheduleScreen> createState() => _TechScheduleScreenState();
}

class _TechScheduleScreenState extends ConsumerState<TechScheduleScreen> {
  bool _isWeekView = false;
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    final jobsAsync = ref.watch(jobsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(colors, jobsAsync),
            _buildViewToggle(colors),
            if (_isWeekView) _buildWeekStrip(colors),
            if (!_isWeekView) _buildDayNav(colors),
            Expanded(
              child: jobsAsync.when(
                loading: () => Center(
                  child: CircularProgressIndicator(color: colors.accentPrimary),
                ),
                error: (e, _) => _buildErrorState(colors, e),
                data: (jobs) {
                  final filtered = _filterByDateRange(jobs);
                  if (filtered.isEmpty) return _buildEmptyState(colors);
                  return RefreshIndicator(
                    onRefresh: () => ref.read(jobsProvider.notifier).loadJobs(),
                    color: colors.accentPrimary,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) =>
                          _buildJobTimeCard(colors, filtered[index]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Job> _filterByDateRange(List<Job> jobs) {
    final now = _selectedDate;
    final dayStart = DateTime(now.year, now.month, now.day);

    if (_isWeekView) {
      // Monday-Sunday of the selected week
      final weekStart = dayStart.subtract(Duration(days: dayStart.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 7));
      return jobs.where((j) {
        final scheduled = j.scheduledStart;
        if (scheduled == null) return false;
        return scheduled.isAfter(weekStart.subtract(const Duration(seconds: 1))) &&
            scheduled.isBefore(weekEnd);
      }).toList()
        ..sort((a, b) =>
            (a.scheduledStart ?? DateTime(2099)).compareTo(b.scheduledStart ?? DateTime(2099)));
    } else {
      // Single day
      final dayEnd = dayStart.add(const Duration(days: 1));
      return jobs.where((j) {
        final scheduled = j.scheduledStart;
        if (scheduled == null) return false;
        return scheduled.isAfter(dayStart.subtract(const Duration(seconds: 1))) &&
            scheduled.isBefore(dayEnd);
      }).toList()
        ..sort((a, b) =>
            (a.scheduledStart ?? DateTime(2099)).compareTo(b.scheduledStart ?? DateTime(2099)));
    }
  }

  Widget _buildHeader(ZaftoColors colors, AsyncValue<List<Job>> jobsAsync) {
    final count = jobsAsync.maybeWhen(
      data: (jobs) => _filterByDateRange(jobs).length,
      orElse: () => 0,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Text(
            'My Schedule',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colors.accentPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count job${count == 1 ? '' : 's'} ${_isWeekView ? 'this week' : 'today'}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.accentPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggle(ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: colors.bgInset,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() {
                  _isWeekView = false;
                  _selectedDate = DateTime.now();
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: !_isWeekView ? colors.bgElevated : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      'Day',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: !_isWeekView ? colors.textPrimary : colors.textTertiary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() {
                  _isWeekView = true;
                  _selectedDate = DateTime.now();
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: _isWeekView ? colors.bgElevated : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      'Week',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _isWeekView ? colors.textPrimary : colors.textTertiary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayNav(ZaftoColors colors) {
    final now = DateTime.now();
    final isToday = _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _selectedDate = _selectedDate.subtract(const Duration(days: 1)));
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colors.bgInset,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(LucideIcons.chevronLeft, size: 18, color: colors.textSecondary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isToday
                  ? 'Today, ${_formatDate(_selectedDate)}'
                  : _formatDate(_selectedDate),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _selectedDate = _selectedDate.add(const Duration(days: 1)));
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colors.bgInset,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(LucideIcons.chevronRight, size: 18, color: colors.textSecondary),
            ),
          ),
          if (!isToday) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _selectedDate = DateTime.now());
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: colors.accentPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Today',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.accentPrimary,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWeekStrip(ZaftoColors colors) {
    final now = DateTime.now();
    final mondayOfWeek = _selectedDate.subtract(
      Duration(days: _selectedDate.weekday - 1),
    );
    final days = List.generate(7, (i) => mondayOfWeek.add(Duration(days: i)));
    const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _selectedDate = _selectedDate.subtract(const Duration(days: 7)));
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colors.bgInset,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(LucideIcons.chevronLeft, size: 16, color: colors.textSecondary),
            ),
          ),
          const SizedBox(width: 8),
          ...List.generate(7, (i) {
            final day = days[i];
            final isToday = day.year == now.year &&
                day.month == now.month &&
                day.day == now.day;

            return Expanded(
              child: Column(
                children: [
                  Text(
                    dayLabels[i],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: colors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isToday ? colors.accentPrimary : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${day.day}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                          color: isToday ? Colors.white : colors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _selectedDate = _selectedDate.add(const Duration(days: 7)));
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colors.bgInset,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(LucideIcons.chevronRight, size: 16, color: colors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobTimeCard(ZaftoColors colors, Job job) {
    final time = job.scheduledStart != null
        ? '${job.scheduledStart!.hour.toString().padLeft(2, '0')}:${job.scheduledStart!.minute.toString().padLeft(2, '0')}'
        : 'TBD';

    final statusColor = _statusColor(job.status, colors);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => JobDetailScreen(jobId: job.id)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.bgElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(color: statusColor, width: 3),
          ),
        ),
        child: Row(
          children: [
            // Time column
            SizedBox(
              width: 48,
              child: Text(
                time,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colors.accentPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Job info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.title ?? 'Untitled Job',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (job.customerName.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      job.customerName,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (job.address.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(LucideIcons.mapPin, size: 11, color: colors.textTertiary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            job.address,
                            style: TextStyle(
                              fontSize: 11,
                              color: colors.textTertiary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Status chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _statusLabel(job.status),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(LucideIcons.chevronRight, size: 16, color: colors.textQuaternary),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ZaftoColors colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.calendarOff,
              size: 48,
              color: colors.textQuaternary,
            ),
            const SizedBox(height: 16),
            Text(
              _isWeekView ? 'No jobs this week' : 'No jobs scheduled today',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Jobs assigned to you will appear here.\nAsk your dispatcher to schedule your work.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: colors.textTertiary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ZaftoColors colors, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.alertCircle, size: 48, color: colors.accentError),
            const SizedBox(height: 16),
            Text(
              'Failed to load schedule',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: colors.textTertiary),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => ref.read(jobsProvider.notifier).loadJobs(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: colors.accentPrimary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(JobStatus status, ZaftoColors colors) {
    switch (status) {
      case JobStatus.scheduled:
        return colors.accentPrimary;
      case JobStatus.dispatched:
        return Colors.blue;
      case JobStatus.enRoute:
        return Colors.orange;
      case JobStatus.inProgress:
        return Colors.amber;
      case JobStatus.onHold:
        return colors.accentWarning;
      case JobStatus.completed:
        return colors.accentSuccess;
      default:
        return colors.textTertiary;
    }
  }

  String _statusLabel(JobStatus status) {
    switch (status) {
      case JobStatus.scheduled:
        return 'Scheduled';
      case JobStatus.dispatched:
        return 'Dispatched';
      case JobStatus.enRoute:
        return 'En Route';
      case JobStatus.inProgress:
        return 'In Progress';
      case JobStatus.onHold:
        return 'On Hold';
      case JobStatus.completed:
        return 'Completed';
      case JobStatus.invoiced:
        return 'Invoiced';
      default:
        return status.name;
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }
}
