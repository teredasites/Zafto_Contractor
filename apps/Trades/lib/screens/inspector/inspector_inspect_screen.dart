import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:zafto/theme/zafto_colors.dart';
import 'package:zafto/theme/theme_provider.dart';
import 'package:zafto/models/inspection.dart';
import 'package:zafto/services/inspection_service.dart';
import 'package:zafto/widgets/inspector/template_picker_sheet.dart';
import 'package:zafto/screens/inspector/inspection_execution_screen.dart';

// ============================================================
// Inspector Inspect Screen — Active & Scheduled Inspections
//
// Lists all active/scheduled inspections with status filtering.
// Start new inspection CTA. Tap any inspection → detail.
// Real data from inspectionsProvider.
// ============================================================

class InspectorInspectScreen extends ConsumerStatefulWidget {
  const InspectorInspectScreen({super.key});

  @override
  ConsumerState<InspectorInspectScreen> createState() => _InspectorInspectScreenState();
}

class _InspectorInspectScreenState extends ConsumerState<InspectorInspectScreen> {
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    final inspectionsAsync = ref.watch(inspectionsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(colors),
            const SizedBox(height: 12),
            _buildFilterChips(colors),
            const SizedBox(height: 12),
            Expanded(
              child: inspectionsAsync.when(
                loading: () => Center(
                  child: CircularProgressIndicator(color: colors.accentPrimary),
                ),
                error: (e, _) => _buildErrorState(colors, e),
                data: (inspections) {
                  final filtered = _applyFilter(inspections);
                  if (filtered.isEmpty) return _buildEmptyState(colors);
                  return RefreshIndicator(
                    onRefresh: () => ref.read(inspectionsProvider.notifier).refresh(),
                    color: colors.accentPrimary,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      itemCount: filtered.length + 1, // +1 for start CTA
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        if (index == 0) return _buildStartCTA(colors);
                        return _buildInspectionCard(colors, filtered[index - 1]);
                      },
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

  List<PmInspection> _applyFilter(List<PmInspection> inspections) {
    switch (_filter) {
      case 'Scheduled':
        return inspections.where((i) => i.status == InspectionStatus.scheduled).toList();
      case 'In Progress':
        return inspections.where((i) => i.status == InspectionStatus.inProgress).toList();
      case 'Completed':
        return inspections.where((i) => i.status == InspectionStatus.completed).toList();
      default:
        return inspections;
    }
  }

  Widget _buildHeader(ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Text(
        'Inspections',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: colors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildFilterChips(ZaftoColors colors) {
    final filters = ['All', 'Scheduled', 'In Progress', 'Completed'];
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _filter == filter;
          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _filter = filter);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? colors.accentPrimary : colors.bgInset,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                filter,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : colors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStartCTA(ZaftoColors colors) {
    return GestureDetector(
      onTap: () async {
        HapticFeedback.lightImpact();
        final template = await showTemplatePicker(context);
        if (template == null || !mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => InspectionExecutionScreen(
              template: template,
              inspectionType: template.inspectionType,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.bgElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colors.accentPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(LucideIcons.plus, color: colors.accentPrimary, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Start New Inspection',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Begin a checklist for a property or job site',
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, size: 18, color: colors.textQuaternary),
          ],
        ),
      ),
    );
  }

  Widget _buildInspectionCard(ZaftoColors colors, PmInspection inspection) {
    final statusColor = _statusColor(inspection.status, colors);
    final time = inspection.scheduledDate != null
        ? '${inspection.scheduledDate!.month}/${inspection.scheduledDate!.day}'
        : 'Unscheduled';

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => InspectionExecutionScreen(
              inspection: inspection,
              template: null, // will load from DB via templateId
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.bgElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border(left: BorderSide(color: statusColor, width: 3)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _statusIcon(inspection.status),
                size: 20,
                color: statusColor,
              ),
            ),
            const SizedBox(width: 12),
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
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        time,
                        style: TextStyle(fontSize: 12, color: colors.textTertiary),
                      ),
                      if ((inspection.notes ?? '').isNotEmpty) ...[
                        Text(' · ', style: TextStyle(fontSize: 12, color: colors.textQuaternary)),
                        Expanded(
                          child: Text(
                            inspection.notes ?? '',
                            style: TextStyle(fontSize: 12, color: colors.textTertiary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if ((inspection.score ?? 0) > 0) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        SizedBox(
                          width: 80,
                          height: 4,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: (inspection.score ?? 0) / 100,
                              backgroundColor: colors.bgInset,
                              valueColor: AlwaysStoppedAnimation(
                                (inspection.score ?? 0) >= 70 ? colors.accentSuccess : colors.accentError,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${inspection.score ?? 0}%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: (inspection.score ?? 0) >= 70 ? colors.accentSuccess : colors.accentError,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _statusLabel(inspection.status),
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
            _buildStartCTA(colors),
            const SizedBox(height: 24),
            Icon(LucideIcons.clipboardCheck, size: 48, color: colors.textQuaternary),
            const SizedBox(height: 16),
            Text(
              _filter == 'All' ? 'No inspections yet' : 'No $_filter inspections',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Inspections assigned to you will appear here.\nStart a new inspection above.',
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
              'Failed to load inspections',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colors.textSecondary),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => ref.read(inspectionsProvider.notifier).refresh(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: colors.accentPrimary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Retry', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(InspectionStatus status, ZaftoColors colors) {
    switch (status) {
      case InspectionStatus.scheduled:
        return colors.accentPrimary;
      case InspectionStatus.inProgress:
        return Colors.amber;
      case InspectionStatus.completed:
        return colors.accentSuccess;
      case InspectionStatus.cancelled:
        return colors.textTertiary;
    }
  }

  IconData _statusIcon(InspectionStatus status) {
    switch (status) {
      case InspectionStatus.scheduled:
        return LucideIcons.calendarCheck;
      case InspectionStatus.inProgress:
        return LucideIcons.play;
      case InspectionStatus.completed:
        return LucideIcons.checkCircle;
      case InspectionStatus.cancelled:
        return LucideIcons.xCircle;
    }
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

  String _statusLabel(InspectionStatus status) {
    switch (status) {
      case InspectionStatus.scheduled:
        return 'Scheduled';
      case InspectionStatus.inProgress:
        return 'In Progress';
      case InspectionStatus.completed:
        return 'Completed';
      case InspectionStatus.cancelled:
        return 'Cancelled';
    }
  }
}
