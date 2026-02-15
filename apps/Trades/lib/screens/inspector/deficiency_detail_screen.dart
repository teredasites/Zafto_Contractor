import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:zafto/theme/zafto_colors.dart';
import 'package:zafto/theme/theme_provider.dart';
import 'package:zafto/models/inspection.dart';
import 'package:zafto/services/inspection_service.dart';

// ============================================================
// Deficiency Detail Screen
//
// Full deficiency info: description, code citation, severity,
// status workflow, photos, remediation, deadline, assignment.
// Status can be advanced through the workflow.
// ============================================================

class DeficiencyDetailScreen extends ConsumerStatefulWidget {
  final InspectionDeficiency deficiency;

  const DeficiencyDetailScreen({super.key, required this.deficiency});

  @override
  ConsumerState<DeficiencyDetailScreen> createState() =>
      _DeficiencyDetailScreenState();
}

class _DeficiencyDetailScreenState
    extends ConsumerState<DeficiencyDetailScreen> {
  late DeficiencyStatus _currentStatus;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.deficiency.status;
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    final d = widget.deficiency;
    final sevColor = _severityColor(d.severity, colors);
    final statusColor = _statusColor(_currentStatus, colors);

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
          'Deficiency',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          // Severity + Status badges
          Row(
            children: [
              _buildBadge(
                  _severityLabel(d.severity).toUpperCase(), sevColor, colors),
              const SizedBox(width: 8),
              _buildBadge(
                  _statusLabel(_currentStatus).toUpperCase(), statusColor, colors),
            ],
          ),
          const SizedBox(height: 16),

          // Description
          Text(
            d.description,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),

          // Code citation
          if (d.codeSection != null)
            _buildInfoRow(
              colors,
              LucideIcons.bookOpen,
              'Code Reference',
              '${d.codeSection}${d.codeTitle != null ? '\n${d.codeTitle}' : ''}',
            ),

          // Remediation
          if (d.remediation != null) ...[
            const SizedBox(height: 16),
            _buildInfoRow(
              colors,
              LucideIcons.wrench,
              'Remediation Required',
              d.remediation!,
            ),
          ],

          // Deadline
          if (d.deadline != null) ...[
            const SizedBox(height: 16),
            _buildInfoRow(
              colors,
              LucideIcons.calendar,
              'Deadline',
              '${d.deadline!.month}/${d.deadline!.day}/${d.deadline!.year}',
              valueColor: _deadlineColor(d, colors),
            ),
          ],

          // Assigned to
          if (d.assignedTo != null) ...[
            const SizedBox(height: 16),
            _buildInfoRow(
              colors,
              LucideIcons.user,
              'Assigned To',
              d.assignedTo!,
            ),
          ],

          // Photos
          if (d.photos.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'PHOTOS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: colors.textTertiary,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: d.photos.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) => Container(
                  width: 100,
                  decoration: BoxDecoration(
                    color: colors.bgInset,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: colors.borderSubtle),
                  ),
                  child: Center(
                    child: Icon(LucideIcons.image,
                        size: 24, color: colors.textQuaternary),
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Status workflow
          Text(
            'STATUS WORKFLOW',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: colors.textTertiary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          _buildStatusWorkflow(colors),

          const SizedBox(height: 24),

          // Created / Updated timestamps
          Row(
            children: [
              Expanded(
                child: _buildTimestamp(colors, 'Created',
                    '${d.createdAt.month}/${d.createdAt.day}/${d.createdAt.year}'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildTimestamp(colors, 'Updated',
                    '${d.updatedAt.month}/${d.updatedAt.day}/${d.updatedAt.year}'),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomActions(colors),
    );
  }

  Widget _buildBadge(String label, Color color, ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    ZaftoColors colors,
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: colors.textTertiary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colors.textTertiary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: valueColor ?? colors.textPrimary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusWorkflow(ZaftoColors colors) {
    const steps = DeficiencyStatus.values;

    return Column(
      children: List.generate(steps.length, (index) {
        final step = steps[index];
        final isActive = step == _currentStatus;
        final isPast = step.index < _currentStatus.index;
        final color = isPast
            ? colors.accentSuccess
            : isActive
                ? _statusColor(step, colors)
                : colors.textQuaternary;

        return Row(
          children: [
            // Dot + line
            SizedBox(
              width: 24,
              child: Column(
                children: [
                  if (index > 0)
                    Container(
                      width: 2,
                      height: 16,
                      color: isPast ? colors.accentSuccess : colors.borderSubtle,
                    ),
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isPast || isActive
                          ? color
                          : Colors.transparent,
                      border: Border.all(color: color, width: 2),
                    ),
                    child: isPast
                        ? const Icon(Icons.check,
                            size: 10, color: Colors.white)
                        : null,
                  ),
                  if (index < steps.length - 1)
                    Container(
                      width: 2,
                      height: 16,
                      color: isPast
                          ? colors.accentSuccess
                          : colors.borderSubtle,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _statusLabel(step),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isPast || isActive
                      ? colors.textPrimary
                      : colors.textQuaternary,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildTimestamp(ZaftoColors colors, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgInset,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: colors.textQuaternary)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildBottomActions(ZaftoColors colors) {
    final nextStatus = _nextStatus(_currentStatus);
    if (nextStatus == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        border: Border(top: BorderSide(color: colors.borderSubtle)),
      ),
      child: GestureDetector(
        onTap: _updating ? null : () => _advanceStatus(nextStatus),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: _updating
                ? colors.accentPrimary.withValues(alpha: 0.5)
                : colors.accentPrimary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: _updating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Mark as ${_statusLabel(nextStatus)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  DeficiencyStatus? _nextStatus(DeficiencyStatus current) {
    switch (current) {
      case DeficiencyStatus.open:
        return DeficiencyStatus.assigned;
      case DeficiencyStatus.assigned:
        return DeficiencyStatus.inProgress;
      case DeficiencyStatus.inProgress:
        return DeficiencyStatus.corrected;
      case DeficiencyStatus.corrected:
        return DeficiencyStatus.verified;
      case DeficiencyStatus.verified:
        return DeficiencyStatus.closed;
      case DeficiencyStatus.closed:
        return null;
    }
  }

  Future<void> _advanceStatus(DeficiencyStatus newStatus) async {
    setState(() => _updating = true);
    try {
      final repo = ref.read(deficiencyRepoProvider);
      await repo.updateStatus(widget.deficiency.id, newStatus);
      setState(() => _currentStatus = newStatus);
      // Refresh global list
      ref.read(deficienciesProvider.notifier).refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: $e'),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  // ──────────────────────────────────────────────
  // HELPERS
  // ──────────────────────────────────────────────

  Color _severityColor(DeficiencySeverity s, ZaftoColors colors) {
    switch (s) {
      case DeficiencySeverity.critical:
        return colors.accentError;
      case DeficiencySeverity.major:
        return Colors.orange;
      case DeficiencySeverity.minor:
        return colors.accentWarning;
      case DeficiencySeverity.info:
        return colors.accentPrimary;
    }
  }

  String _severityLabel(DeficiencySeverity s) {
    switch (s) {
      case DeficiencySeverity.critical:
        return 'Critical';
      case DeficiencySeverity.major:
        return 'Major';
      case DeficiencySeverity.minor:
        return 'Minor';
      case DeficiencySeverity.info:
        return 'Info';
    }
  }

  Color _statusColor(DeficiencyStatus s, ZaftoColors colors) {
    switch (s) {
      case DeficiencyStatus.open:
        return colors.accentError;
      case DeficiencyStatus.assigned:
        return colors.accentPrimary;
      case DeficiencyStatus.inProgress:
        return Colors.amber;
      case DeficiencyStatus.corrected:
        return colors.accentSuccess;
      case DeficiencyStatus.verified:
        return colors.accentSuccess;
      case DeficiencyStatus.closed:
        return colors.textTertiary;
    }
  }

  String _statusLabel(DeficiencyStatus s) {
    switch (s) {
      case DeficiencyStatus.open:
        return 'Open';
      case DeficiencyStatus.assigned:
        return 'Assigned';
      case DeficiencyStatus.inProgress:
        return 'In Progress';
      case DeficiencyStatus.corrected:
        return 'Corrected';
      case DeficiencyStatus.verified:
        return 'Verified';
      case DeficiencyStatus.closed:
        return 'Closed';
    }
  }

  Color _deadlineColor(InspectionDeficiency d, ZaftoColors colors) {
    if (d.status == DeficiencyStatus.closed ||
        d.status == DeficiencyStatus.verified) {
      return colors.textTertiary;
    }
    if (d.deadline == null) return colors.textTertiary;
    final daysLeft = d.deadline!.difference(DateTime.now()).inDays;
    if (daysLeft < 0) return colors.accentError;
    if (daysLeft <= 2) return colors.accentWarning;
    return colors.textTertiary;
  }
}
