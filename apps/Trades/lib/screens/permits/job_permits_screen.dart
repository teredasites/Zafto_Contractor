// ZAFTO Job Permits Screen — Per-job permit tracker with status timeline
// Shows all permits for a job, status progression, inspection schedules.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/theme_provider.dart';
import '../../theme/zafto_colors.dart';
import '../../models/job_permit.dart';
import '../../providers/permit_intelligence_provider.dart';

class JobPermitsScreen extends ConsumerWidget {
  final String jobId;
  const JobPermitsScreen({super.key, required this.jobId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);
    final permitsAsync = ref.watch(jobPermitsProvider(jobId));

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        title: Text('Job Permits', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      body: permitsAsync.when(
        loading: () => Center(child: CircularProgressIndicator(color: colors.accentPrimary)),
        error: (e, _) => _ErrorState(colors: colors),
        data: (permits) {
          if (permits.isEmpty) return _EmptyState(colors: colors);
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: permits.length,
            itemBuilder: (context, i) => _PermitCard(permit: permits[i], colors: colors),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final ZaftoColors colors;
  const _EmptyState({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.fileCheck, color: colors.textSecondary, size: 48),
          const SizedBox(height: 12),
          Text('No permits for this job', style: TextStyle(color: colors.textSecondary, fontSize: 16)),
          const SizedBox(height: 8),
          Text('Add a permit to track its progress', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final ZaftoColors colors;
  const _ErrorState({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.alertTriangle, color: colors.error, size: 48),
          const SizedBox(height: 12),
          Text('Failed to load permits', style: TextStyle(color: colors.textSecondary)),
        ],
      ),
    );
  }
}

class _PermitCard extends StatelessWidget {
  final JobPermit permit;
  final ZaftoColors colors;
  const _PermitCard({required this.permit, required this.colors});

  Color _statusColor() {
    switch (permit.status) {
      case PermitStatus.approved:
      case PermitStatus.active:
        return colors.success;
      case PermitStatus.denied:
        return colors.error;
      case PermitStatus.expired:
        return Colors.orange;
      case PermitStatus.correctionsNeeded:
        return Colors.amber;
      case PermitStatus.pendingReview:
      case PermitStatus.applied:
        return colors.accentPrimary;
      default:
        return colors.textTertiary;
    }
  }

  IconData _statusIcon() {
    switch (permit.status) {
      case PermitStatus.approved:
      case PermitStatus.active:
        return LucideIcons.checkCircle;
      case PermitStatus.denied:
        return LucideIcons.xCircle;
      case PermitStatus.expired:
        return LucideIcons.alertTriangle;
      case PermitStatus.correctionsNeeded:
        return LucideIcons.alertCircle;
      case PermitStatus.pendingReview:
        return LucideIcons.clock;
      case PermitStatus.applied:
        return LucideIcons.send;
      default:
        return LucideIcons.fileCheck;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: _statusColor().withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_statusIcon(), color: _statusColor(), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        permit.permitType,
                        style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      if (permit.permitNumber != null)
                        Text(
                          '#${permit.permitNumber}',
                          style: TextStyle(color: colors.textTertiary, fontSize: 12),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor().withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    permit.status.label,
                    style: TextStyle(color: _statusColor(), fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

          // Status Timeline
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _StatusTimeline(permit: permit, colors: colors),
          ),

          // Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (permit.feePaid != null)
                  _DetailRow(icon: LucideIcons.dollarSign, label: 'Fee', value: '\$${permit.feePaid!.toStringAsFixed(2)}', colors: colors),
                if (permit.applicationDate != null)
                  _DetailRow(icon: LucideIcons.calendar, label: 'Applied', value: _formatDate(permit.applicationDate!), colors: colors),
                if (permit.approvalDate != null)
                  _DetailRow(icon: LucideIcons.checkCircle, label: 'Approved', value: _formatDate(permit.approvalDate!), colors: colors),
                if (permit.expirationDate != null)
                  _DetailRow(
                    icon: LucideIcons.alertTriangle,
                    label: 'Expires',
                    value: _formatDate(permit.expirationDate!),
                    colors: colors,
                    highlight: permit.isExpiringSoon,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}

class _StatusTimeline extends StatelessWidget {
  final JobPermit permit;
  final ZaftoColors colors;
  const _StatusTimeline({required this.permit, required this.colors});

  @override
  Widget build(BuildContext context) {
    final stages = [
      ('Not Started', PermitStatus.notStarted),
      ('Applied', PermitStatus.applied),
      ('In Review', PermitStatus.pendingReview),
      ('Approved', PermitStatus.approved),
      ('Active', PermitStatus.active),
    ];

    final currentIndex = stages.indexWhere((s) => s.$2 == permit.status);
    final effectiveIndex = currentIndex >= 0 ? currentIndex : 0;

    return Row(
      children: List.generate(stages.length * 2 - 1, (i) {
        if (i.isOdd) {
          // Connector line
          final stageIndex = i ~/ 2;
          final isCompleted = stageIndex < effectiveIndex;
          return Expanded(
            child: Container(
              height: 2,
              color: isCompleted ? colors.success : colors.borderDefault,
            ),
          );
        }
        final stageIndex = i ~/ 2;
        final isCompleted = stageIndex <= effectiveIndex;
        final isCurrent = stageIndex == effectiveIndex;
        return Column(
          children: [
            Container(
              width: isCurrent ? 14 : 10,
              height: isCurrent ? 14 : 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted ? colors.success : colors.bgCard,
                border: Border.all(
                  color: isCompleted ? colors.success : colors.borderDefault,
                  width: isCurrent ? 3 : 1,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              stages[stageIndex].$1,
              style: TextStyle(
                fontSize: 9,
                color: isCompleted ? colors.textPrimary : colors.textTertiary,
                fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ZaftoColors colors;
  final bool highlight;
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.colors,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 14, color: highlight ? Colors.orange : colors.textTertiary),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 13, color: colors.textSecondary)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: highlight ? Colors.orange : colors.textPrimary,
              fontWeight: highlight ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
