/// ZAFTO Time Clock Screen
/// Session 23 - February 2026
///
/// Full-featured time clock with:
/// - Large clock in/out button
/// - Elapsed time display
/// - Break tracking
/// - Job assignment
/// - Recent time entries

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:geolocator/geolocator.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../models/time_entry.dart';
import '../../services/time_clock_service.dart';
import '../../services/job_service.dart';
import '../../models/job.dart';

class TimeClockScreen extends ConsumerStatefulWidget {
  const TimeClockScreen({super.key});

  @override
  ConsumerState<TimeClockScreen> createState() => _TimeClockScreenState();
}

class _TimeClockScreenState extends ConsumerState<TimeClockScreen>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  late AnimationController _pulseController;
  bool _isLoading = false;
  String? _selectedJobId;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    // Update every second
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<GpsLocation?> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showError('Location permission denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showError('Location permissions permanently denied');
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      return GpsLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
      );
    } catch (e) {
      _showError('Could not get location');
      return null;
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _handleClockIn() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    HapticFeedback.heavyImpact();

    try {
      final location = await _getCurrentLocation();
      if (location == null) {
        setState(() => _isLoading = false);
        return;
      }

      await ref.read(activeClockEntryProvider.notifier).clockIn(
        location,
        jobId: _selectedJobId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Clocked in successfully'),
            backgroundColor: Color(0xFF22C55E),
          ),
        );
      }
    } catch (e) {
      _showError('Clock in failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleClockOut() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    HapticFeedback.heavyImpact();

    try {
      final location = await _getCurrentLocation();
      if (location == null) {
        setState(() => _isLoading = false);
        return;
      }

      final entry = ref.read(activeClockEntryProvider);
      await ref.read(activeClockEntryProvider.notifier).clockOut(location);

      if (mounted && entry != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Clocked out - ${entry.workedTimeFormatted} worked'),
            backgroundColor: const Color(0xFF3B82F6),
          ),
        );
      }
    } catch (e) {
      _showError('Clock out failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleBreakToggle() async {
    final entry = ref.read(activeClockEntryProvider);
    if (entry == null) return;

    HapticFeedback.mediumImpact();

    try {
      final hasActiveBreak = entry.breaks.isNotEmpty && entry.breaks.last.isActive;

      if (hasActiveBreak) {
        await ref.read(activeClockEntryProvider.notifier).endBreak();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Break ended')),
          );
        }
      } else {
        await ref.read(activeClockEntryProvider.notifier).startBreak();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Break started')),
          );
        }
      }
    } catch (e) {
      _showError('Break action failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    final activeEntry = ref.watch(activeClockEntryProvider);
    final isClockedIn = activeEntry != null;
    final hasActiveBreak = activeEntry?.breaks.isNotEmpty == true &&
        activeEntry!.breaks.last.isActive;

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
          'Time Clock',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.history, color: colors.textSecondary),
            onPressed: () => _showTimeHistory(colors),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 32),

            // Main clock display
            _buildClockDisplay(colors, activeEntry, hasActiveBreak),

            const SizedBox(height: 40),

            // Main action button
            _buildMainButton(colors, isClockedIn),

            const SizedBox(height: 24),

            // Break button (only when clocked in)
            if (isClockedIn) ...[
              _buildBreakButton(colors, hasActiveBreak),
              const SizedBox(height: 32),
            ],

            // Job selector (only when not clocked in)
            if (!isClockedIn) ...[
              _buildJobSelector(colors),
              const SizedBox(height: 32),
            ],

            // Stats cards
            _buildStatsSection(colors),

            const SizedBox(height: 24),

            // Recent entries
            _buildRecentEntries(colors),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildClockDisplay(ZaftoColors colors, ClockEntry? entry, bool onBreak) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final isClockedIn = entry != null;
        final pulseValue = isClockedIn && !onBreak ? _pulseController.value * 0.15 : 0.0;

        return Container(
          width: 220,
          height: 220,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: isClockedIn
                  ? onBreak
                      ? [
                          const Color(0xFFF59E0B).withOpacity(0.2),
                          const Color(0xFFF59E0B).withOpacity(0.05),
                        ]
                      : [
                          const Color(0xFF22C55E).withOpacity(0.15 + pulseValue),
                          const Color(0xFF22C55E).withOpacity(0.05),
                        ]
                  : [
                      colors.bgElevated,
                      colors.bgBase,
                    ],
            ),
            border: Border.all(
              color: isClockedIn
                  ? onBreak
                      ? const Color(0xFFF59E0B).withOpacity(0.5)
                      : const Color(0xFF22C55E).withOpacity(0.4 + pulseValue)
                  : colors.borderSubtle,
              width: 3,
            ),
            boxShadow: isClockedIn && !onBreak
                ? [
                    BoxShadow(
                      color: const Color(0xFF22C55E).withOpacity(0.2 + pulseValue * 0.2),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                onBreak
                    ? LucideIcons.coffee
                    : isClockedIn
                        ? LucideIcons.clock
                        : LucideIcons.play,
                size: 40,
                color: onBreak
                    ? const Color(0xFFF59E0B)
                    : isClockedIn
                        ? const Color(0xFF22C55E)
                        : colors.textTertiary,
              ),
              const SizedBox(height: 12),
              Text(
                isClockedIn ? entry!.workedTimeFormatted : '0h 0m',
                style: TextStyle(
                  color: onBreak
                      ? const Color(0xFFF59E0B)
                      : isClockedIn
                          ? const Color(0xFF22C55E)
                          : colors.textTertiary,
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                onBreak
                    ? 'ON BREAK'
                    : isClockedIn
                        ? 'WORKING'
                        : 'NOT CLOCKED IN',
                style: TextStyle(
                  color: onBreak
                      ? const Color(0xFFF59E0B)
                      : isClockedIn
                          ? const Color(0xFF22C55E)
                          : colors.textTertiary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMainButton(ZaftoColors colors, bool isClockedIn) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _isLoading
              ? null
              : (isClockedIn ? _handleClockOut : _handleClockIn),
          style: ElevatedButton.styleFrom(
            backgroundColor: isClockedIn
                ? const Color(0xFFEF4444)
                : const Color(0xFF22C55E),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isClockedIn ? LucideIcons.logOut : LucideIcons.logIn,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isClockedIn ? 'CLOCK OUT' : 'CLOCK IN',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildBreakButton(ZaftoColors colors, bool onBreak) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: OutlinedButton(
          onPressed: _handleBreakToggle,
          style: OutlinedButton.styleFrom(
            foregroundColor: onBreak
                ? const Color(0xFF22C55E)
                : const Color(0xFFF59E0B),
            side: BorderSide(
              color: onBreak
                  ? const Color(0xFF22C55E)
                  : const Color(0xFFF59E0B),
              width: 1.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                onBreak ? LucideIcons.play : LucideIcons.coffee,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                onBreak ? 'END BREAK' : 'START BREAK',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJobSelector(ZaftoColors colors) {
    final jobs = ref.watch(activeJobsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ASSIGN TO JOB (OPTIONAL)',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: colors.bgElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.borderSubtle),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: _selectedJobId,
                isExpanded: true,
                hint: Text(
                  'Select a job',
                  style: TextStyle(color: colors.textTertiary),
                ),
                dropdownColor: colors.bgElevated,
                icon: Icon(LucideIcons.chevronDown, color: colors.textSecondary),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text('No job', style: TextStyle(color: colors.textSecondary)),
                  ),
                  ...jobs.map((job) => DropdownMenuItem(
                    value: job.id,
                    child: Text(
                      job.displayTitle,
                      style: TextStyle(color: colors.textPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  )),
                ],
                onChanged: (value) => setState(() => _selectedJobId = value),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(ZaftoColors colors) {
    final stats = ref.watch(timeClockStatsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildStatCard(
            colors,
            'This Week',
            '${stats.totalHoursThisWeek.toStringAsFixed(1)}h',
            LucideIcons.calendar,
            const Color(0xFF3B82F6),
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            colors,
            'Pending',
            stats.pendingApproval.toString(),
            LucideIcons.clock,
            const Color(0xFFF59E0B),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    ZaftoColors colors,
    String label,
    String value,
    IconData icon,
    Color accentColor,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.bgElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: accentColor),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: colors.textTertiary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentEntries(ZaftoColors colors) {
    final entriesAsync = ref.watch(userTimeEntriesProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'RECENT ENTRIES',
                style: TextStyle(
                  color: colors.textTertiary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
              TextButton(
                onPressed: () => _showTimeHistory(colors),
                child: Text(
                  'View All',
                  style: TextStyle(
                    color: colors.accentPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          entriesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e', style: TextStyle(color: colors.error)),
            data: (entries) {
              final recent = entries.take(5).toList();
              if (recent.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: colors.bgElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.borderSubtle),
                  ),
                  child: Center(
                    child: Text(
                      'No time entries yet',
                      style: TextStyle(color: colors.textTertiary),
                    ),
                  ),
                );
              }

              return Column(
                children: recent.map((entry) => _buildEntryCard(colors, entry)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEntryCard(ZaftoColors colors, ClockEntry entry) {
    final dateStr = _formatDate(entry.clockIn);
    final timeStr = '${_formatTime(entry.clockIn)} - ${entry.clockOut != null ? _formatTime(entry.clockOut!) : 'Active'}';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: entry.isActive
                  ? const Color(0xFF22C55E).withOpacity(0.15)
                  : colors.bgBase,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              entry.isActive ? LucideIcons.clock : LucideIcons.checkCircle,
              size: 20,
              color: entry.isActive
                  ? const Color(0xFF22C55E)
                  : colors.textTertiary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateStr,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  timeStr,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                entry.totalHours != null
                    ? '${entry.totalHours!.toStringAsFixed(1)}h'
                    : entry.workedTimeFormatted,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              _buildStatusBadge(colors, entry.status),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(ZaftoColors colors, ClockEntryStatus status) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case ClockEntryStatus.active:
        bgColor = const Color(0xFF22C55E).withOpacity(0.15);
        textColor = const Color(0xFF22C55E);
        label = 'Active';
        break;
      case ClockEntryStatus.completed:
        bgColor = const Color(0xFFF59E0B).withOpacity(0.15);
        textColor = const Color(0xFFF59E0B);
        label = 'Pending';
        break;
      case ClockEntryStatus.approved:
        bgColor = const Color(0xFF3B82F6).withOpacity(0.15);
        textColor = const Color(0xFF3B82F6);
        label = 'Approved';
        break;
      case ClockEntryStatus.rejected:
        bgColor = const Color(0xFFEF4444).withOpacity(0.15);
        textColor = const Color(0xFFEF4444);
        label = 'Rejected';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dt.year, dt.month, dt.day);

    if (date == today) return 'Today';
    if (date == today.subtract(const Duration(days: 1))) return 'Yesterday';

    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month - 1]} ${dt.day}';
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${dt.minute.toString().padLeft(2, '0')} $ampm';
  }

  void _showTimeHistory(ZaftoColors colors) {
    // Navigate to full time history screen (or show bottom sheet)
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.bgBase,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => _TimeHistorySheet(
          scrollController: scrollController,
        ),
      ),
    );
  }
}

class _TimeHistorySheet extends ConsumerWidget {
  final ScrollController scrollController;

  const _TimeHistorySheet({required this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);
    final entriesAsync = ref.watch(userTimeEntriesProvider);

    return Column(
      children: [
        // Handle bar
        Container(
          margin: const EdgeInsets.only(top: 12),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: colors.borderSubtle,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Time History',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              IconButton(
                icon: Icon(LucideIcons.x, color: colors.textSecondary),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        Expanded(
          child: entriesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (entries) {
              if (entries.isEmpty) {
                return Center(
                  child: Text(
                    'No time entries',
                    style: TextStyle(color: colors.textTertiary),
                  ),
                );
              }

              return ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  return _buildHistoryItem(colors, entry);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryItem(ZaftoColors colors, ClockEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatFullDate(entry.clockIn),
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                entry.totalHours != null
                    ? '${entry.totalHours!.toStringAsFixed(2)} hours'
                    : 'Active',
                style: TextStyle(
                  color: entry.totalHours != null
                      ? colors.textPrimary
                      : const Color(0xFF22C55E),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(LucideIcons.logIn, size: 14, color: colors.textTertiary),
              const SizedBox(width: 4),
              Text(
                _formatTime(entry.clockIn),
                style: TextStyle(color: colors.textSecondary, fontSize: 13),
              ),
              const SizedBox(width: 16),
              if (entry.clockOut != null) ...[
                Icon(LucideIcons.logOut, size: 14, color: colors.textTertiary),
                const SizedBox(width: 4),
                Text(
                  _formatTime(entry.clockOut!),
                  style: TextStyle(color: colors.textSecondary, fontSize: 13),
                ),
              ],
            ],
          ),
          if (entry.breaks.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(LucideIcons.coffee, size: 14, color: colors.textTertiary),
                const SizedBox(width: 4),
                Text(
                  '${entry.breaks.length} break(s) - ${_formatDuration(entry.totalBreakTime)}',
                  style: TextStyle(color: colors.textTertiary, fontSize: 12),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatFullDate(DateTime dt) {
    final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${days[dt.weekday % 7]}, ${months[dt.month - 1]} ${dt.day}';
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${dt.minute.toString().padLeft(2, '0')} $ampm';
  }

  String _formatDuration(Duration d) {
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes % 60}m';
    }
    return '${d.inMinutes}m';
  }
}
