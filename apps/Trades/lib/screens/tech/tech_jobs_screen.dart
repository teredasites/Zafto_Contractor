import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:zafto/theme/theme_provider.dart';
import 'package:zafto/theme/zafto_colors.dart';
import 'package:zafto/models/job.dart';
import 'package:zafto/services/job_service.dart';
import 'package:zafto/screens/jobs/job_detail_screen.dart';
import 'package:zafto/widgets/shared/matrix_rain_painter.dart';

// ============================================================
// Tech Jobs Screen — Real data, filtered for field tech
//
// Shows jobs assigned to the current tech with filter chips
// (Today, Upcoming, In Progress, Recent). Tapping a job
// navigates to JobDetailScreen.
// ============================================================

class TechJobsScreen extends ConsumerStatefulWidget {
  const TechJobsScreen({super.key});

  @override
  ConsumerState<TechJobsScreen> createState() => _TechJobsScreenState();
}

class _TechJobsScreenState extends ConsumerState<TechJobsScreen> {
  String _selectedFilter = 'today';

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
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'My Jobs',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 14),
            _buildFilterChips(colors),
            const SizedBox(height: 12),
            Expanded(
              child: jobsAsync.when(
                loading: () => Center(
                  child: CircularProgressIndicator(color: colors.accentPrimary),
                ),
                error: (e, _) => _buildErrorState(colors, e),
                data: (jobs) {
                  final filtered = _filterJobs(jobs);
                  if (filtered.isEmpty) return _buildEmptyState(colors);
                  return RefreshIndicator(
                    onRefresh: () => ref.read(jobsProvider.notifier).loadJobs(),
                    color: colors.accentPrimary,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) => _buildJobCard(colors, filtered[index]),
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

  // ── Filter Chips ──────────────────────────────────────────
  Widget _buildFilterChips(ZaftoColors colors) {
    final filters = [
      ('today', 'Today'),
      ('in_progress', 'In Progress'),
      ('upcoming', 'Upcoming'),
      ('recent', 'Recent'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: filters.map((f) {
          final isSelected = _selectedFilter == f.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _selectedFilter = f.$1);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? crmEmerald : colors.bgElevated,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? crmEmerald : colors.borderSubtle,
                  ),
                ),
                child: Text(
                  f.$2,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : colors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Job Card ──────────────────────────────────────────────
  Widget _buildJobCard(ZaftoColors colors, Job job) {
    final (statusColor, statusIcon) = _statusVisuals(colors, job.status);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => JobDetailScreen(jobId: job.id)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.bgElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: status badge + time
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 12, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        job.statusLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
                if (job.priority == JobPriority.high || job.priority == JobPriority.urgent) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.alertTriangle, size: 11, color: Colors.red.shade400),
                        const SizedBox(width: 3),
                        Text(
                          job.priority == JobPriority.urgent ? 'URGENT' : 'HIGH',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.red.shade400),
                        ),
                      ],
                    ),
                  ),
                ],
                const Spacer(),
                if (job.scheduledStart != null)
                  Text(
                    _formatTime(job.scheduledStart!),
                    style: TextStyle(fontSize: 12, color: colors.textTertiary),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            // Job title
            Text(
              job.displayTitle,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            // Customer + Address
            if (job.customerName.isNotEmpty)
              Row(
                children: [
                  Icon(LucideIcons.user, size: 13, color: colors.textTertiary),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      job.customerName,
                      style: TextStyle(fontSize: 13, color: colors.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            if (job.address.isNotEmpty) ...[
              const SizedBox(height: 3),
              Row(
                children: [
                  Icon(LucideIcons.mapPin, size: 13, color: colors.textTertiary),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      job.fullAddress,
                      style: TextStyle(fontSize: 12, color: colors.textTertiary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            // Job type badge for insurance/warranty
            if (job.jobType != JobType.standard) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (job.isInsuranceClaim ? const Color(0xFFF59E0B) : const Color(0xFF8B5CF6))
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  job.jobTypeLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: job.isInsuranceClaim ? const Color(0xFFF59E0B) : const Color(0xFF8B5CF6),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Filter Logic ──────────────────────────────────────────
  List<Job> _filterJobs(List<Job> jobs) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final tomorrowStart = todayStart.add(const Duration(days: 1));

    switch (_selectedFilter) {
      case 'today':
        return jobs.where((j) {
          if (j.scheduledStart == null) return false;
          return j.scheduledStart!.isAfter(todayStart) &&
              j.scheduledStart!.isBefore(tomorrowStart) &&
              j.status != JobStatus.cancelled;
        }).toList()
          ..sort((a, b) => (a.scheduledStart ?? now).compareTo(b.scheduledStart ?? now));

      case 'in_progress':
        return jobs.where((j) =>
            j.status == JobStatus.inProgress ||
            j.status == JobStatus.enRoute ||
            j.status == JobStatus.dispatched).toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      case 'upcoming':
        return jobs.where((j) {
          if (j.scheduledStart == null) return false;
          return j.scheduledStart!.isAfter(tomorrowStart) &&
              j.status != JobStatus.cancelled &&
              j.status != JobStatus.completed &&
              j.status != JobStatus.invoiced;
        }).toList()
          ..sort((a, b) => (a.scheduledStart!).compareTo(b.scheduledStart!));

      case 'recent':
        return jobs.where((j) =>
            j.status == JobStatus.completed || j.status == JobStatus.invoiced).toList()
          ..sort((a, b) => (b.completedAt ?? b.updatedAt)
              .compareTo(a.completedAt ?? a.updatedAt))
          ..take(20).toList();

      default:
        return jobs;
    }
  }

  // ── Status Visuals ────────────────────────────────────────
  (Color, IconData) _statusVisuals(ZaftoColors colors, JobStatus status) {
    return switch (status) {
      JobStatus.draft => (colors.textTertiary, LucideIcons.inbox),
      JobStatus.scheduled => (colors.accentInfo, LucideIcons.calendar),
      JobStatus.dispatched => (colors.accentInfo, LucideIcons.truck),
      JobStatus.enRoute => (const Color(0xFF6366F1), LucideIcons.navigation),
      JobStatus.inProgress => (colors.accentSuccess, LucideIcons.play),
      JobStatus.onHold => (colors.accentWarning, LucideIcons.pauseCircle),
      JobStatus.completed => (colors.accentPrimary, LucideIcons.checkCircle),
      JobStatus.invoiced => (colors.accentSuccess, LucideIcons.fileText),
      JobStatus.cancelled => (colors.textTertiary, LucideIcons.x),
    };
  }

  // ── Empty State ───────────────────────────────────────────
  Widget _buildEmptyState(ZaftoColors colors) {
    final (icon, message, subtitle) = switch (_selectedFilter) {
      'today' => (LucideIcons.calendarOff, 'No jobs scheduled for today', 'Check your upcoming jobs or ask the office'),
      'in_progress' => (LucideIcons.play, 'No active jobs', 'Jobs you start will appear here'),
      'upcoming' => (LucideIcons.calendar, 'No upcoming jobs', 'Future scheduled jobs will appear here'),
      'recent' => (LucideIcons.history, 'No completed jobs yet', 'Your completed work history will appear here'),
      _ => (LucideIcons.briefcase, 'No jobs found', 'Jobs assigned to you will appear here'),
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: colors.fillDefault,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, size: 28, color: colors.textQuaternary),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(fontSize: 13, color: colors.textTertiary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ── Error State ───────────────────────────────────────────
  Widget _buildErrorState(ZaftoColors colors, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.alertCircle, size: 40, color: colors.accentWarning),
            const SizedBox(height: 12),
            Text(
              'Failed to load jobs',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              'Pull down to retry',
              style: TextStyle(fontSize: 13, color: colors.textTertiary),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => ref.read(jobsProvider.notifier).loadJobs(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: colors.accentPrimary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Retry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${dt.minute.toString().padLeft(2, '0')} $period';
  }
}
