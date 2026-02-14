// ZAFTO Inspection Result Screen — Log pass/fail, photos, corrections
// Per-permit inspection detail: schedule, result entry, failure tracking.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/theme_provider.dart';
import '../../theme/zafto_colors.dart';
import '../../models/permit_inspection.dart';
import '../../providers/permit_intelligence_provider.dart';

class InspectionResultScreen extends ConsumerWidget {
  final String jobPermitId;
  const InspectionResultScreen({super.key, required this.jobPermitId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);
    final inspectionsAsync = ref.watch(permitInspectionsProvider(jobPermitId));

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        title: Text('Inspections', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      body: inspectionsAsync.when(
        loading: () => Center(child: CircularProgressIndicator(color: colors.accentPrimary)),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.alertTriangle, color: colors.error, size: 48),
              const SizedBox(height: 12),
              Text('Failed to load inspections', style: TextStyle(color: colors.textSecondary)),
            ],
          ),
        ),
        data: (inspections) {
          if (inspections.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.clipboardCheck, color: colors.textSecondary, size: 48),
                  const SizedBox(height: 12),
                  Text('No inspections scheduled', style: TextStyle(color: colors.textSecondary, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('Inspections will appear here once scheduled', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
                ],
              ),
            );
          }

          // Summary stats
          final passed = inspections.where((i) => i.isPassed).length;
          final failed = inspections.where((i) => i.isFailed).length;
          final pending = inspections.where((i) => i.result == null).length;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Stats Row
              Row(
                children: [
                  _StatChip(label: 'Passed', count: passed, color: colors.success, colors: colors),
                  const SizedBox(width: 8),
                  _StatChip(label: 'Failed', count: failed, color: colors.error, colors: colors),
                  const SizedBox(width: 8),
                  _StatChip(label: 'Pending', count: pending, color: colors.accentPrimary, colors: colors),
                ],
              ),
              const SizedBox(height: 20),

              // Timeline
              ...inspections.asMap().entries.map((entry) {
                final index = entry.key;
                final inspection = entry.value;
                final isLast = index == inspections.length - 1;
                return _InspectionTimelineItem(
                  inspection: inspection,
                  isLast: isLast,
                  colors: colors,
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final ZaftoColors colors;
  const _StatChip({required this.label, required this.count, required this.color, required this.colors});

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
            Text('$count', style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _InspectionTimelineItem extends StatelessWidget {
  final PermitInspection inspection;
  final bool isLast;
  final ZaftoColors colors;
  const _InspectionTimelineItem({required this.inspection, required this.isLast, required this.colors});

  Color _resultColor() {
    if (inspection.result == null) return colors.textTertiary;
    switch (inspection.result!) {
      case InspectionResult.pass:
        return colors.success;
      case InspectionResult.fail:
        return colors.error;
      case InspectionResult.partial:
        return Colors.amber;
      case InspectionResult.cancelled:
        return colors.textTertiary;
      case InspectionResult.rescheduled:
        return colors.accentPrimary;
    }
  }

  IconData _resultIcon() {
    if (inspection.result == null) return LucideIcons.clock;
    switch (inspection.result!) {
      case InspectionResult.pass:
        return LucideIcons.checkCircle;
      case InspectionResult.fail:
        return LucideIcons.xCircle;
      case InspectionResult.partial:
        return LucideIcons.alertCircle;
      case InspectionResult.cancelled:
        return LucideIcons.ban;
      case InspectionResult.rescheduled:
        return LucideIcons.calendarClock;
    }
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline dot + line
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 20, height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _resultColor().withValues(alpha: 0.15),
                    border: Border.all(color: _resultColor(), width: 2),
                  ),
                  child: Icon(_resultIcon(), size: 10, color: _resultColor()),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: colors.borderDefault,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.bgCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.borderDefault),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          inspection.inspectionType,
                          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                      ),
                      if (inspection.result != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _resultColor().withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            inspection.result!.label,
                            style: TextStyle(color: _resultColor(), fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        )
                      else
                        Text('Scheduled', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Dates
                  if (inspection.scheduledDate != null)
                    _MetaRow(icon: LucideIcons.calendar, text: 'Scheduled: ${_formatDate(inspection.scheduledDate!)}', colors: colors),
                  if (inspection.completedDate != null)
                    _MetaRow(icon: LucideIcons.checkSquare, text: 'Completed: ${_formatDate(inspection.completedDate!)}', colors: colors),
                  if (inspection.inspectorName != null)
                    _MetaRow(icon: LucideIcons.user, text: 'Inspector: ${inspection.inspectorName}', colors: colors),
                  if (inspection.inspectorPhone != null)
                    _MetaRow(icon: LucideIcons.phone, text: inspection.inspectorPhone!, colors: colors),

                  // Failure details
                  if (inspection.isFailed) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colors.error.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: colors.error.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (inspection.failureReason != null) ...[
                            Text('Failure Reason', style: TextStyle(color: colors.error, fontSize: 11, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text(inspection.failureReason!, style: TextStyle(color: colors.textPrimary, fontSize: 13)),
                          ],
                          if (inspection.correctionNotes != null) ...[
                            const SizedBox(height: 8),
                            Text('Corrections Required', style: TextStyle(color: colors.error, fontSize: 11, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text(inspection.correctionNotes!, style: TextStyle(color: colors.textPrimary, fontSize: 13)),
                          ],
                          if (inspection.correctionDeadline != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(LucideIcons.alertTriangle, size: 12, color: Colors.orange),
                                const SizedBox(width: 6),
                                Text(
                                  'Correction deadline: ${_formatDate(inspection.correctionDeadline!)}',
                                  style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  // Reinspection
                  if (inspection.reinspectionNeeded) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: colors.accentPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.refreshCw, size: 12, color: colors.accentPrimary),
                          const SizedBox(width: 6),
                          Text(
                            inspection.reinspectionDate != null
                                ? 'Reinspection: ${_formatDate(inspection.reinspectionDate!)}'
                                : 'Reinspection needed',
                            style: TextStyle(color: colors.accentPrimary, fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Photos
                  if (inspection.photos.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(LucideIcons.camera, size: 12, color: colors.textTertiary),
                        const SizedBox(width: 6),
                        Text(
                          '${inspection.photos.length} photo${inspection.photos.length > 1 ? 's' : ''}',
                          style: TextStyle(color: colors.textTertiary, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.month}/${date.day}/${date.year}';
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final ZaftoColors colors;
  const _MetaRow({required this.icon, required this.text, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 12, color: colors.textTertiary),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}
