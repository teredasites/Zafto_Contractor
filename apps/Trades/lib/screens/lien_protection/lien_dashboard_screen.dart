// ZAFTO Lien Dashboard — Active liens sorted by deadline, status colors
// Shows at-risk amounts, approaching deadlines, lien statuses.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/theme_provider.dart';
import '../../theme/zafto_colors.dart';
import '../../models/lien_tracking.dart';
import '../../providers/lien_provider.dart';
import 'lien_detail_screen.dart';

class LienDashboardScreen extends ConsumerWidget {
  const LienDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);
    final liensAsync = ref.watch(activeLiensProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        title: Text('Lien Protection', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      body: liensAsync.when(
        loading: () => Center(child: CircularProgressIndicator(color: colors.accentPrimary)),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.alertTriangle, color: colors.error, size: 48),
              const SizedBox(height: 12),
              Text('Failed to load liens', style: TextStyle(color: colors.textSecondary)),
            ],
          ),
        ),
        data: (liens) {
          if (liens.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.shield, color: colors.textSecondary, size: 48),
                  const SizedBox(height: 12),
                  Text('No active lien records', style: TextStyle(color: colors.textSecondary, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('Liens will appear here when jobs are tracked', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
                ],
              ),
            );
          }

          // Stats
          final totalOwed = liens.fold<double>(0, (sum, l) => sum + (l.amountOwed ?? 0));
          final urgent = liens.where((l) => l.status.isUrgent).length;
          final filed = liens.where((l) => l.lienFiled).length;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Summary stats
              Row(
                children: [
                  _StatChip(label: 'At Risk', value: '\$${totalOwed.toStringAsFixed(0)}', color: Colors.orange, colors: colors),
                  const SizedBox(width: 8),
                  _StatChip(label: 'Urgent', value: '$urgent', color: colors.error, colors: colors),
                  const SizedBox(width: 8),
                  _StatChip(label: 'Filed', value: '$filed', color: colors.accentPrimary, colors: colors),
                  const SizedBox(width: 8),
                  _StatChip(label: 'Active', value: '${liens.length}', color: colors.success, colors: colors),
                ],
              ),
              const SizedBox(height: 20),

              // Lien list
              ...liens.map((lien) => _LienCard(lien: lien, colors: colors)),
            ],
          );
        },
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final ZaftoColors colors;
  const _StatChip({required this.label, required this.value, required this.color, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _LienCard extends StatelessWidget {
  final LienTracking lien;
  final ZaftoColors colors;
  const _LienCard({required this.lien, required this.colors});

  Color _statusColor() {
    switch (lien.status) {
      case LienStatus.noticeDue:
      case LienStatus.enforcement:
        return colors.error;
      case LienStatus.lienEligible:
      case LienStatus.lienFiled:
        return Colors.orange;
      case LienStatus.noticeSent:
        return colors.accentPrimary;
      case LienStatus.paymentReceived:
      case LienStatus.lienReleased:
      case LienStatus.resolved:
        return colors.success;
      default:
        return colors.textTertiary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => LienDetailScreen(lienId: lien.id, jobId: lien.jobId)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: lien.status.isUrgent ? colors.error.withValues(alpha: 0.3) : colors.borderDefault),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: _statusColor().withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(LucideIcons.shield, color: _statusColor(), size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lien.propertyAddress,
                        style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${lien.stateCode} - ${lien.propertyCity ?? ''}',
                        style: TextStyle(color: colors.textTertiary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _statusColor().withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    lien.status.label,
                    style: TextStyle(color: _statusColor(), fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                if (lien.amountOwed != null && lien.amountOwed! > 0) ...[
                  Icon(LucideIcons.dollarSign, size: 12, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text('\$${lien.amountOwed!.toStringAsFixed(2)}', style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 16),
                ],
                if (lien.lastWorkDate != null) ...[
                  Icon(LucideIcons.calendar, size: 12, color: colors.textTertiary),
                  const SizedBox(width: 4),
                  Text('Last: ${lien.lastWorkDate!.month}/${lien.lastWorkDate!.day}/${lien.lastWorkDate!.year}', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
                ],
                const Spacer(),
                Icon(LucideIcons.chevronRight, size: 16, color: colors.textTertiary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
