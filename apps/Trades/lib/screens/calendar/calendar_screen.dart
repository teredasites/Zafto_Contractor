/// ZAFTO Calendar Screen
/// Sprint P0 - February 2026
/// Visual job scheduling with week and month views

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../models/scheduled_item.dart';
import '../../services/calendar_service.dart';
import '../jobs/job_detail_screen.dart';
import '../jobs/job_create_screen.dart';

enum CalendarView { week, month }

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  CalendarView _currentView = CalendarView.week;
  late DateTime _focusedDate;
  late PageController _weekPageController;

  @override
  void initState() {
    super.initState();
    _focusedDate = DateTime.now();
    _weekPageController = PageController(initialPage: 1000);
  }

  @override
  void dispose() {
    _weekPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final daySchedule = ref.watch(selectedDateScheduleProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgElevated,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: GestureDetector(
          onTap: () => _goToToday(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _focusedDate.monthName,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              Text(
                '${_focusedDate.year}',
                style: TextStyle(fontSize: 12, color: colors.textTertiary),
              ),
            ],
          ),
        ),
        actions: [
          // View toggle
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: colors.fillDefault,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildViewToggle(colors, CalendarView.week, LucideIcons.columns),
                _buildViewToggle(colors, CalendarView.month, LucideIcons.layoutGrid),
              ],
            ),
          ),
          IconButton(
            icon: Icon(LucideIcons.plus, color: colors.accentPrimary),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const JobCreateScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Calendar view (week or month)
          if (_currentView == CalendarView.week)
            _buildWeekView(colors)
          else
            _buildMonthView(colors),

          // Divider
          Container(height: 1, color: colors.borderSubtle),

          // Selected day header
          _buildSelectedDayHeader(colors, selectedDate),

          // Day schedule
          Expanded(
            child: daySchedule.isEmpty
                ? _buildEmptyState(colors, selectedDate)
                : _buildDaySchedule(colors, daySchedule),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: colors.accentPrimary,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const JobCreateScreen()),
        ),
        child: Icon(
          LucideIcons.plus,
          color: colors.isDark ? Colors.black : Colors.white,
        ),
      ),
    );
  }

  Widget _buildViewToggle(ZaftoColors colors, CalendarView view, IconData icon) {
    final isSelected = _currentView == view;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _currentView = view);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? colors.accentPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isSelected
              ? (colors.isDark ? Colors.black : Colors.white)
              : colors.textTertiary,
        ),
      ),
    );
  }

  Widget _buildWeekView(ZaftoColors colors) {
    return SizedBox(
      height: 100,
      child: PageView.builder(
        controller: _weekPageController,
        onPageChanged: (page) {
          final weeksFromNow = page - 1000;
          setState(() {
            _focusedDate = DateTime.now().add(Duration(days: weeksFromNow * 7));
          });
        },
        itemBuilder: (context, page) {
          final weeksFromNow = page - 1000;
          final weekStart = _getStartOfWeek(
            DateTime.now().add(Duration(days: weeksFromNow * 7)),
          );
          return _buildWeekRow(colors, weekStart);
        },
      ),
    );
  }

  Widget _buildWeekRow(ZaftoColors colors, DateTime weekStart) {
    final selectedDate = ref.watch(selectedDateProvider);
    final monthStats = ref.watch(monthStatsProvider(_focusedDate));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: List.generate(7, (index) {
          final date = weekStart.add(Duration(days: index));
          final isSelected = date.isSameDay(selectedDate);
          final isToday = date.isSameDay(DateTime.now());
          final stats = monthStats[date.normalized];
          final hasJobs = stats?.hasItems ?? false;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                ref.read(selectedDateProvider.notifier).state = date;
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colors.accentPrimary
                      : (isToday ? colors.accentPrimary.withOpacity(0.1) : null),
                  borderRadius: BorderRadius.circular(12),
                  border: isToday && !isSelected
                      ? Border.all(color: colors.accentPrimary, width: 2)
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      date.dayAbbreviation,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? (colors.isDark ? Colors.black : Colors.white)
                            : colors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${date.day}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? (colors.isDark ? Colors.black : Colors.white)
                            : colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Job indicator dot
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: hasJobs
                            ? (isSelected
                                ? (colors.isDark ? Colors.black : Colors.white)
                                : colors.accentSuccess)
                            : Colors.transparent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildMonthView(ZaftoColors colors) {
    final selectedDate = ref.watch(selectedDateProvider);
    final monthStats = ref.watch(monthStatsProvider(_focusedDate));

    final firstOfMonth = DateTime(_focusedDate.year, _focusedDate.month, 1);
    final daysInMonth = DateTime(_focusedDate.year, _focusedDate.month + 1, 0).day;
    final startWeekday = firstOfMonth.weekday; // Monday = 1

    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Month navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(LucideIcons.chevronLeft, color: colors.textSecondary),
                onPressed: () {
                  setState(() {
                    _focusedDate = DateTime(_focusedDate.year, _focusedDate.month - 1);
                  });
                },
              ),
              Text(
                '${_focusedDate.monthName} ${_focusedDate.year}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              IconButton(
                icon: Icon(LucideIcons.chevronRight, color: colors.textSecondary),
                onPressed: () {
                  setState(() {
                    _focusedDate = DateTime(_focusedDate.year, _focusedDate.month + 1);
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Day headers
          Row(
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                .map((day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: colors.textTertiary,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),

          // Calendar grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
            ),
            itemCount: 42, // 6 weeks
            itemBuilder: (context, index) {
              final dayOffset = index - (startWeekday - 1);
              if (dayOffset < 1 || dayOffset > daysInMonth) {
                return const SizedBox();
              }

              final date = DateTime(_focusedDate.year, _focusedDate.month, dayOffset);
              final isSelected = date.isSameDay(selectedDate);
              final isToday = date.isSameDay(DateTime.now());
              final stats = monthStats[date.normalized];
              final hasJobs = stats?.hasItems ?? false;

              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  ref.read(selectedDateProvider.notifier).state = date;
                },
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : null,
                    borderRadius: BorderRadius.circular(8),
                    border: isToday && !isSelected
                        ? Border.all(color: colors.accentPrimary, width: 2)
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$dayOffset',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? (colors.isDark ? Colors.black : Colors.white)
                              : colors.textPrimary,
                        ),
                      ),
                      if (hasJobs)
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? (colors.isDark ? Colors.black : Colors.white)
                                : colors.accentSuccess,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedDayHeader(ZaftoColors colors, DateTime date) {
    final isToday = date.isSameDay(DateTime.now());

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Text(
            isToday
                ? 'Today'
                : '${date.dayAbbreviation}, ${date.monthAbbreviation} ${date.day}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          if (isToday)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: colors.accentPrimary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${date.monthAbbreviation} ${date.day}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.accentPrimary,
                ),
              ),
            ),
          const Spacer(),
          TextButton.icon(
            icon: Icon(LucideIcons.plus, size: 16, color: colors.accentPrimary),
            label: Text(
              'Add Job',
              style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const JobCreateScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ZaftoColors colors, DateTime date) {
    final isToday = date.isSameDay(DateTime.now());

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: colors.fillDefault,
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.calendarOff,
              size: 28,
              color: colors.textTertiary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isToday ? 'No jobs scheduled today' : 'No jobs scheduled',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to schedule a job',
            style: TextStyle(fontSize: 14, color: colors.textTertiary),
          ),
          const SizedBox(height: 80), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildDaySchedule(ZaftoColors colors, List<ScheduledItem> items) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildScheduleCard(colors, item);
      },
    );
  }

  Widget _buildScheduleCard(ZaftoColors colors, ScheduledItem item) {
    return GestureDetector(
      onTap: () {
        if (item.jobId != null) {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => JobDetailScreen(jobId: item.jobId!),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.bgElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.borderSubtle),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Time indicator
            Container(
              width: 4,
              height: 60,
              decoration: BoxDecoration(
                color: item.color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 16),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: item.color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.timeDisplay,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: item.color,
                          ),
                        ),
                      ),
                      if (item.durationMinutes != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          item.durationDisplay,
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textTertiary,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  if (item.customerName != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.customerName!,
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                  if (item.address != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          LucideIcons.mapPin,
                          size: 12,
                          color: colors.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.address!,
                            style: TextStyle(
                              fontSize: 12,
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

            // Chevron
            Icon(
              LucideIcons.chevronRight,
              size: 20,
              color: colors.textQuaternary,
            ),
          ],
        ),
      ),
    );
  }

  DateTime _getStartOfWeek(DateTime date) {
    final weekday = date.weekday;
    return DateTime(date.year, date.month, date.day - (weekday - 1));
  }

  void _goToToday() {
    HapticFeedback.lightImpact();
    setState(() {
      _focusedDate = DateTime.now();
    });
    ref.read(selectedDateProvider.notifier).state = DateTime.now();
    _weekPageController.animateToPage(
      1000,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
}
