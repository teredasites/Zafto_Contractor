/// Jobs Hub Screen - Design System v2.6
/// Sprint 5.0 - January 2026

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../models/job.dart';
import '../../services/job_service.dart';
import 'job_detail_screen.dart';
import 'job_create_screen.dart';

class JobsHubScreen extends ConsumerStatefulWidget {
  const JobsHubScreen({super.key});
  @override
  ConsumerState<JobsHubScreen> createState() => _JobsHubScreenState();
}

class _JobsHubScreenState extends ConsumerState<JobsHubScreen> {
  JobStatus? _filterStatus;

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    final jobsAsync = ref.watch(jobsProvider);
    final stats = ref.watch(jobStatsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Jobs', style: TextStyle(fontWeight: FontWeight.w600, color: colors.textPrimary)),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.search, color: colors.textSecondary),
            onPressed: () => HapticFeedback.lightImpact(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatsBar(colors, stats),
          _buildFilterChips(colors),
          Expanded(
            child: jobsAsync.when(
              loading: () => Center(child: CircularProgressIndicator(color: colors.accentPrimary)),
              error: (e, _) => Center(child: Text('Error: $e', style: TextStyle(color: colors.textSecondary))),
              data: (jobs) {
                final filtered = _filterStatus == null ? jobs : jobs.where((j) => j.status == _filterStatus).toList();
                if (filtered.isEmpty) return _buildEmptyState(colors);
                return _buildJobsList(colors, filtered);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createJob(context),
        backgroundColor: colors.accentPrimary,
        child: Icon(LucideIcons.plus, color: colors.isDark ? Colors.black : Colors.white),
      ),
    );
  }

  Widget _buildStatsBar(ZaftoColors colors, JobStats stats) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        children: [
          _buildStatItem(colors, '${stats.activeJobs}', 'Active', colors.accentSuccess),
          _buildStatDivider(colors),
          _buildStatItem(colors, '${stats.completedJobs}', 'Done', colors.accentInfo),
          _buildStatDivider(colors),
          _buildStatItem(colors, '\$${_formatAmount(stats.totalRevenue)}', 'Revenue', colors.textPrimary),
        ],
      ),
    );
  }

  Widget _buildStatItem(ZaftoColors colors, String value, String label, Color valueColor) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: valueColor)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: colors.textTertiary)),
        ],
      ),
    );
  }

  Widget _buildStatDivider(ZaftoColors colors) {
    return Container(width: 1, height: 32, color: colors.borderSubtle);
  }

  Widget _buildFilterChips(ZaftoColors colors) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildChip(colors, 'All', null),
          _buildChip(colors, 'Active', JobStatus.inProgress),
          _buildChip(colors, 'Scheduled', JobStatus.scheduled),
          _buildChip(colors, 'Completed', JobStatus.completed),
          _buildChip(colors, 'Drafts', JobStatus.draft),
        ],
      ),
    );
  }

  Widget _buildChip(ZaftoColors colors, String label, JobStatus? status) {
    final isSelected = _filterStatus == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _filterStatus = status);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? colors.accentPrimary : colors.fillDefault,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildJobsList(ZaftoColors colors, List<Job> jobs) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: jobs.length,
      itemBuilder: (context, index) => _buildJobCard(colors, jobs[index]),
    );
  }

  Widget _buildJobCard(ZaftoColors colors, Job job) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => JobDetailScreen(jobId: job.id))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.bgElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildStatusBadge(colors, job.status),
                const Spacer(),
                if (job.scheduledStart != null)
                  Text(_formatDate(job.scheduledStart!), style: TextStyle(fontSize: 12, color: colors.textTertiary)),
              ],
            ),
            const SizedBox(height: 10),
            Text(job.displayTitle, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colors.textPrimary)),
            if (job.customerName.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(job.customerName, style: TextStyle(fontSize: 14, color: colors.textSecondary)),
            ],
            if (job.address.isNotEmpty) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(LucideIcons.mapPin, size: 12, color: colors.textTertiary),
                  const SizedBox(width: 4),
                  Expanded(child: Text(job.address, style: TextStyle(fontSize: 12, color: colors.textTertiary), overflow: TextOverflow.ellipsis)),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Text('\$${_formatAmount(job.estimatedAmount)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colors.textPrimary)),
                const Spacer(),
                Icon(LucideIcons.chevronRight, size: 18, color: colors.textQuaternary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ZaftoColors colors, JobStatus status) {
    final (color, bgColor) = switch (status) {
      JobStatus.draft => (colors.textTertiary, colors.fillDefault),
      JobStatus.dispatched => (colors.accentInfo, colors.accentInfo.withValues(alpha: 0.15)),
      JobStatus.enRoute => (colors.accentInfo, colors.accentInfo.withValues(alpha: 0.15)),
      JobStatus.onHold => (colors.accentWarning, colors.accentWarning.withValues(alpha: 0.15)),
      JobStatus.scheduled => (colors.accentInfo, colors.accentInfo.withValues(alpha: 0.15)),
      JobStatus.inProgress => (colors.accentSuccess, colors.accentSuccess.withValues(alpha: 0.15)),
      JobStatus.completed => (colors.accentPrimary, colors.accentPrimary.withValues(alpha: 0.15)),
      JobStatus.invoiced => (colors.accentSuccess, colors.accentSuccess.withValues(alpha: 0.15)),
      JobStatus.cancelled => (colors.textTertiary, colors.fillDefault),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(6)),
      child: Text(status.name[0].toUpperCase() + status.name.substring(1), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _buildEmptyState(ZaftoColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: colors.fillDefault, shape: BoxShape.circle),
            child: Icon(LucideIcons.briefcase, size: 40, color: colors.textTertiary),
          ),
          const SizedBox(height: 16),
          Text('No jobs yet', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: colors.textPrimary)),
          const SizedBox(height: 6),
          Text('Tap + to create your first job', style: TextStyle(fontSize: 14, color: colors.textTertiary)),
        ],
      ),
    );
  }

  void _createJob(BuildContext context) {
    HapticFeedback.mediumImpact();
    Navigator.push(context, MaterialPageRoute(builder: (_) => const JobCreateScreen()));
  }

  String _formatAmount(double amount) {
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(1)}k';
    return amount.toStringAsFixed(0);
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    return '${date.month}/${date.day}';
  }
}
