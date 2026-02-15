import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:zafto/theme/zafto_colors.dart';
import 'package:zafto/theme/theme_provider.dart';
import 'package:zafto/models/inspection.dart';
import 'package:zafto/services/inspection_service.dart';

// ============================================================
// Compliance Calendar Screen
//
// Shows upcoming required inspections across all properties/
// projects with deadlines. Groups by time: overdue, today,
// this week, upcoming. Visual timeline with status indicators.
// ============================================================

class ComplianceCalendarScreen extends ConsumerWidget {
  const ComplianceCalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);
    final inspectionsAsync = ref.watch(inspectionsProvider);

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
          'Compliance Calendar',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
      ),
      body: inspectionsAsync.when(
        loading: () =>
            Center(child: CircularProgressIndicator(color: colors.accentPrimary)),
        error: (e, _) => _buildError(colors, 'Failed to load inspections'),
        data: (inspections) => _buildBody(context, colors, inspections, ref),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ZaftoColors colors,
      List<PmInspection> inspections, WidgetRef ref) {
    final service = ref.read(inspectionServiceProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endOfWeek = today.add(const Duration(days: 7));
    final endOfMonth = today.add(const Duration(days: 30));

    // Only scheduled/in-progress inspections
    final scheduled = inspections
        .where((i) =>
            i.status == InspectionStatus.scheduled ||
            i.status == InspectionStatus.inProgress)
        .toList()
      ..sort((a, b) {
        final aDate = a.scheduledDate ?? DateTime(2099);
        final bDate = b.scheduledDate ?? DateTime(2099);
        return aDate.compareTo(bDate);
      });

    // Group by time period
    final overdue = <PmInspection>[];
    final todayList = <PmInspection>[];
    final thisWeek = <PmInspection>[];
    final upcoming = <PmInspection>[];
    final unscheduled = <PmInspection>[];

    for (final i in scheduled) {
      if (i.scheduledDate == null) {
        unscheduled.add(i);
        continue;
      }
      final d = DateTime(
          i.scheduledDate!.year, i.scheduledDate!.month, i.scheduledDate!.day);
      if (d.isBefore(today)) {
        overdue.add(i);
      } else if (d.isAtSameMomentAs(today)) {
        todayList.add(i);
      } else if (d.isBefore(endOfWeek)) {
        thisWeek.add(i);
      } else {
        upcoming.add(i);
      }
    }

    // Completed count this month
    final completedThisMonth = inspections
        .where((i) =>
            i.status == InspectionStatus.completed &&
            i.completedDate != null &&
            i.completedDate!.isAfter(today.subtract(const Duration(days: 30))))
        .length;

    // Pass rate
    final passRate = service.passRate(inspections);

    if (scheduled.isEmpty && completedThisMonth == 0) {
      return _buildEmptyState(colors);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        // Stats row
        Row(
          children: [
            _buildStatChip(colors, '${scheduled.length}', 'Pending',
                colors.accentPrimary),
            const SizedBox(width: 8),
            _buildStatChip(
                colors, '$completedThisMonth', 'Done (30d)',
                colors.accentSuccess),
            const SizedBox(width: 8),
            _buildStatChip(colors, '${passRate.toStringAsFixed(0)}%',
                'Pass Rate', colors.accentWarning),
            if (overdue.isNotEmpty) ...[
              const SizedBox(width: 8),
              _buildStatChip(colors, '${overdue.length}', 'Overdue',
                  colors.accentError),
            ],
          ],
        ),
        const SizedBox(height: 20),

        // Sections
        if (overdue.isNotEmpty)
          _buildSection(colors, 'OVERDUE', overdue, colors.accentError),
        if (todayList.isNotEmpty)
          _buildSection(colors, 'TODAY', todayList, colors.accentPrimary),
        if (thisWeek.isNotEmpty)
          _buildSection(colors, 'THIS WEEK', thisWeek, colors.accentWarning),
        if (upcoming.isNotEmpty)
          _buildSection(colors, 'UPCOMING', upcoming, colors.textTertiary),
        if (unscheduled.isNotEmpty)
          _buildSection(
              colors, 'UNSCHEDULED', unscheduled, colors.textQuaternary),
      ],
    );
  }

  Widget _buildSection(ZaftoColors colors, String title,
      List<PmInspection> items, Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                color: accentColor,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${items.length}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: accentColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...items.map((i) => _buildInspectionRow(colors, i, accentColor)),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildInspectionRow(
      ZaftoColors colors, PmInspection inspection, Color accent) {
    final dateStr = inspection.scheduledDate != null
        ? DateFormat('EEE, MMM d').format(inspection.scheduledDate!)
        : 'No date set';
    final timeStr = inspection.scheduledDate != null
        ? DateFormat.jm().format(inspection.scheduledDate!)
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: accent, width: 3)),
      ),
      child: Row(
        children: [
          // Date column
          SizedBox(
            width: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: accent,
                  ),
                ),
                if (timeStr.isNotEmpty)
                  Text(
                    timeStr,
                    style: TextStyle(
                      fontSize: 11,
                      color: colors.textTertiary,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _typeLabel(inspection.inspectionType),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                if ((inspection.notes ?? '').isNotEmpty)
                  Text(
                    inspection.notes!,
                    style: TextStyle(fontSize: 12, color: colors.textTertiary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              inspection.status == InspectionStatus.inProgress
                  ? 'Active'
                  : 'Scheduled',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: accent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(
      ZaftoColors colors, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ZaftoColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.calendarCheck2, size: 48, color: colors.textQuaternary),
          const SizedBox(height: 16),
          Text(
            'No upcoming inspections',
            style: TextStyle(fontSize: 15, color: colors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            'Schedule inspections from the Inspections tab',
            style: TextStyle(fontSize: 13, color: colors.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildError(ZaftoColors colors, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.alertCircle, size: 48, color: colors.accentError),
          const SizedBox(height: 16),
          Text(message,
              style: TextStyle(fontSize: 15, color: colors.textSecondary)),
        ],
      ),
    );
  }

  String _typeLabel(InspectionType type) {
    const labels = <InspectionType, String>{
      InspectionType.moveIn: 'Move-In',
      InspectionType.moveOut: 'Move-Out',
      InspectionType.routine: 'Routine',
      InspectionType.annual: 'Annual',
      InspectionType.maintenance: 'Maintenance',
      InspectionType.safety: 'Safety',
      InspectionType.roughIn: 'Rough-In',
      InspectionType.framing: 'Framing',
      InspectionType.foundation: 'Foundation',
      InspectionType.finalInspection: 'Final',
      InspectionType.permit: 'Permit',
      InspectionType.codeCompliance: 'Code Compliance',
      InspectionType.qcHoldPoint: 'QC Hold Point',
      InspectionType.reInspection: 'Re-Inspection',
      InspectionType.swppp: 'SWPPP',
      InspectionType.environmental: 'Environmental',
      InspectionType.ada: 'ADA',
      InspectionType.insuranceDamage: 'Insurance Damage',
      InspectionType.tpi: 'TPI',
      InspectionType.preConstruction: 'Pre-Construction',
      InspectionType.roofing: 'Roofing',
      InspectionType.fireLifeSafety: 'Fire/Life Safety',
      InspectionType.electrical: 'Electrical',
      InspectionType.plumbing: 'Plumbing',
      InspectionType.hvac: 'HVAC',
    };
    return labels[type] ?? type.name;
  }
}
