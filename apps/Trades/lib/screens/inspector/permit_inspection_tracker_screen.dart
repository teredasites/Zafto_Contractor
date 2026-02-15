import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:zafto/theme/zafto_colors.dart';
import 'package:zafto/theme/theme_provider.dart';
import 'package:zafto/models/job_permit.dart';
import 'package:zafto/models/permit_inspection.dart';

// ============================================================
// Permit Inspection Tracker Screen
//
// Maps permits to their required inspection stages.
// Shows completion progress per permit. Tracks Certificate
// of Occupancy eligibility (all required inspections passed).
// ============================================================

/// Required inspection stages per permit type.
/// Each permit type maps to a list of inspection stage names.
const _permitInspectionStages = <String, List<String>>{
  'building': [
    'Foundation',
    'Framing',
    'Rough-In (MEP)',
    'Insulation',
    'Drywall',
    'Final',
  ],
  'electrical': [
    'Underground/Slab',
    'Rough-In',
    'Service/Panel',
    'Final',
  ],
  'plumbing': [
    'Underground/Slab',
    'Rough-In',
    'Water Heater',
    'Final',
  ],
  'mechanical': [
    'Rough-In',
    'Ductwork',
    'Equipment Set',
    'Final',
  ],
  'roofing': [
    'Deck/Substrate',
    'Underlayment',
    'Final',
  ],
  'demolition': [
    'Pre-Demo',
    'Hazmat Clearance',
    'Final',
  ],
  'grading': [
    'Pre-Grade',
    'Rough Grade',
    'Final Grade',
    'Erosion Control',
  ],
  'fire': [
    'Underground',
    'Rough-In',
    'Hydrostatic Test',
    'Final',
  ],
};

/// Default stages for unknown permit types.
const _defaultStages = ['Pre-Work', 'Rough-In', 'Final'];

/// Provider to load permits for a company.
final _companyPermitsProvider =
    FutureProvider.autoDispose<List<JobPermit>>((ref) async {
  // Placeholder — will be wired to real PermitIntelligenceRepository
  // when permit data pipeline is connected.
  return [];
});

/// Provider to load permit inspections for a specific permit.
final _permitInspectionsProvider =
    FutureProvider.autoDispose.family<List<PermitInspection>, String>(
        (ref, permitId) async {
  return [];
});

class PermitInspectionTrackerScreen extends ConsumerWidget {
  const PermitInspectionTrackerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);
    final permitsAsync = ref.watch(_companyPermitsProvider);

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
          'Permit Inspections',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
      ),
      body: permitsAsync.when(
        loading: () =>
            Center(child: CircularProgressIndicator(color: colors.accentPrimary)),
        error: (e, _) => _buildError(colors, 'Failed to load permits'),
        data: (permits) {
          if (permits.isEmpty) return _buildEmptyState(colors);
          return _buildPermitList(colors, permits, ref);
        },
      ),
    );
  }

  Widget _buildPermitList(
      ZaftoColors colors, List<JobPermit> permits, WidgetRef ref) {
    // Separate active vs inactive
    final active = permits.where((p) => p.status.isActive).toList();
    final other = permits.where((p) => !p.status.isActive).toList();

    // CO eligibility: all active permits have all inspections passed
    final coEligible = active.isNotEmpty; // Will be computed per-permit below

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        // CO status card
        _buildCOStatusCard(colors, active),
        const SizedBox(height: 20),

        if (active.isNotEmpty) ...[
          _buildSectionLabel(colors, 'ACTIVE PERMITS'),
          ...active.map((p) => _buildPermitCard(colors, p, ref)),
          const SizedBox(height: 16),
        ],
        if (other.isNotEmpty) ...[
          _buildSectionLabel(colors, 'OTHER PERMITS'),
          ...other.map((p) => _buildPermitCard(colors, p, ref)),
        ],
      ],
    );
  }

  Widget _buildCOStatusCard(ZaftoColors colors, List<JobPermit> activePermits) {
    // If no active permits, can't determine CO eligibility
    if (activePermits.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.bgElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colors.textQuaternary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(LucideIcons.building2, color: colors.textQuaternary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Certificate of Occupancy',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'No active permits — submit permits to track CO eligibility',
                    style: TextStyle(fontSize: 12, color: colors.textTertiary),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // For now, CO is "pending" — real logic would check all permit inspections
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.accentWarning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.accentWarning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(LucideIcons.building2, color: colors.accentWarning, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Certificate of Occupancy',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${activePermits.length} active permit${activePermits.length == 1 ? '' : 's'} — complete all required inspections for CO eligibility',
                  style: TextStyle(fontSize: 12, color: colors.textTertiary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: colors.accentWarning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'PENDING',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: colors.accentWarning,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermitCard(ZaftoColors colors, JobPermit permit, WidgetRef ref) {
    final stages = _permitInspectionStages[permit.permitType.toLowerCase()] ??
        _defaultStages;
    final statusColor = _permitStatusColor(permit.status, colors);

    // For now, show stages as a visual checklist
    // Real implementation: cross-reference with permit_inspections table
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${permit.permitType} Permit',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    if (permit.permitNumber != null)
                      Text(
                        '#${permit.permitNumber}',
                        style: TextStyle(fontSize: 12, color: colors.textTertiary),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  permit.status.label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Progress bar
          _buildProgressBar(colors, stages, 0, stages.length),
          const SizedBox(height: 10),

          // Inspection stages
          ...stages.asMap().entries.map((entry) {
            return _buildStageRow(colors, entry.value, false); // all unchecked for now
          }),

          // Expiration warning
          if (permit.expirationDate != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(LucideIcons.calendarClock, size: 14, color: colors.textTertiary),
                const SizedBox(width: 6),
                Text(
                  'Expires ${DateFormat('MMM d, yyyy').format(permit.expirationDate!)}',
                  style: TextStyle(fontSize: 12, color: colors.textTertiary),
                ),
                if (permit.expirationDate!.isBefore(DateTime.now())) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: colors.accentError.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'EXPIRED',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: colors.accentError,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStageRow(ZaftoColors colors, String stageName, bool completed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: completed
                  ? colors.accentSuccess.withValues(alpha: 0.1)
                  : colors.borderSubtle.withValues(alpha: 0.3),
              border: Border.all(
                color: completed ? colors.accentSuccess : colors.borderSubtle,
                width: 1.5,
              ),
            ),
            child: completed
                ? Icon(LucideIcons.check, size: 12, color: colors.accentSuccess)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              stageName,
              style: TextStyle(
                fontSize: 13,
                fontWeight: completed ? FontWeight.w600 : FontWeight.w400,
                color: completed ? colors.textPrimary : colors.textSecondary,
                decoration: completed ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          Text(
            completed ? 'Passed' : 'Pending',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: completed ? colors.accentSuccess : colors.textQuaternary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(
      ZaftoColors colors, List<String> stages, int completed, int total) {
    final progress = total > 0 ? completed / total : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '$completed / $total stages completed',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: colors.textTertiary,
              ),
            ),
            const Spacer(),
            Text(
              '${(progress * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: progress >= 1.0
                    ? colors.accentSuccess
                    : colors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: colors.borderSubtle.withValues(alpha: 0.3),
            valueColor: AlwaysStoppedAnimation(
              progress >= 1.0 ? colors.accentSuccess : colors.accentPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(ZaftoColors colors, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
          color: colors.textTertiary,
        ),
      ),
    );
  }

  Widget _buildEmptyState(ZaftoColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.fileStack, size: 48, color: colors.textQuaternary),
          const SizedBox(height: 16),
          Text(
            'No permits found',
            style: TextStyle(fontSize: 15, color: colors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            'Permits will appear here when created from the CRM',
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

  Color _permitStatusColor(PermitStatus status, ZaftoColors colors) {
    switch (status) {
      case PermitStatus.notStarted:
        return colors.textQuaternary;
      case PermitStatus.applied:
      case PermitStatus.pendingReview:
        return colors.accentWarning;
      case PermitStatus.correctionsNeeded:
        return colors.accentError;
      case PermitStatus.approved:
      case PermitStatus.active:
        return colors.accentSuccess;
      case PermitStatus.expired:
        return colors.accentError;
      case PermitStatus.closed:
        return colors.textTertiary;
      case PermitStatus.denied:
        return colors.accentError;
    }
  }
}
