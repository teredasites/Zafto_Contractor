import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// ZAFTO Result Card - Design System v2.6 / Phase 0.5
///
/// Displays calculator results with gradient background.
///
/// Structure:
/// ┌─────────────────────────────────────────────────┐
/// │              VOLTAGE DROP                        │
/// │                 2.84%                            │
/// │     3.41V drop at 120V · Within NEC limits      │
/// │                                                  │
/// │        [Copy Result]  [Add to Job]              │
/// └─────────────────────────────────────────────────┘
///
/// Spec: S8_02_5_DESIGN_SPEC_LOCKED.md
///
/// Usage:
/// ```dart
/// ZaftoResultCard(
///   label: 'VOLTAGE DROP',
///   value: '2.84%',
///   subtitle: '3.41V drop at 120V',
///   status: ResultStatus.success,
///   statusText: 'Within NEC limits',
///   onCopy: () => _copyToClipboard(),
///   onAddToJob: () => _addToJob(),
/// )
/// ```

enum ResultStatus {
  success,
  warning,
  error,
  neutral,
}

class ZaftoResultCard extends ConsumerWidget {
  /// Label displayed at the top (e.g., "VOLTAGE DROP")
  final String label;

  /// The main result value (e.g., "2.84%")
  final String value;

  /// Optional subtitle text
  final String? subtitle;

  /// Result status for color theming
  final ResultStatus status;

  /// Optional status text (e.g., "Within NEC limits")
  final String? statusText;

  /// Callback when copy button is tapped
  final VoidCallback? onCopy;

  /// Callback when add to job button is tapped
  final VoidCallback? onAddToJob;

  /// Additional action buttons
  final List<ZaftoResultAction>? actions;

  /// Whether to show the status badge
  final bool showStatusBadge;

  const ZaftoResultCard({
    super.key,
    required this.label,
    required this.value,
    this.subtitle,
    this.status = ResultStatus.success,
    this.statusText,
    this.onCopy,
    this.onAddToJob,
    this.actions,
    this.showStatusBadge = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);
    final statusColor = _getStatusColor(colors);

    return Container(
      // Spec: 24px padding
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        // Spec: gradient Green 8% to Green 3%
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            statusColor.withOpacity(0.08),
            statusColor.withOpacity(0.03),
          ],
        ),
        // Spec: border Green 15%
        border: Border.all(
          color: statusColor.withOpacity(0.15),
        ),
        // Spec: 16px border radius
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Label - Spec: 11px, w600, textTertiary, letter-spacing 0.5px
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colors.textTertiary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          // Value - Spec: 40px, w700, status color
          Text(
            value,
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w700,
              color: statusColor,
            ),
          ),
          if (subtitle != null || statusText != null) ...[
            const SizedBox(height: 8),
            // Subtitle with optional status - Spec: 13px, textSecondary
            _buildSubtitleRow(colors, statusColor),
          ],
          if (_hasActions) ...[
            const SizedBox(height: 20),
            // Actions - Spec: 12px gap
            _buildActions(colors),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(ZaftoColors colors) {
    switch (status) {
      case ResultStatus.success:
        return colors.accentSuccess;
      case ResultStatus.warning:
        return colors.accentWarning;
      case ResultStatus.error:
        return colors.accentError;
      case ResultStatus.neutral:
        return colors.textSecondary;
    }
  }

  IconData _getStatusIcon() {
    switch (status) {
      case ResultStatus.success:
        return LucideIcons.check;
      case ResultStatus.warning:
        return LucideIcons.alertTriangle;
      case ResultStatus.error:
        return LucideIcons.xCircle;
      case ResultStatus.neutral:
        return LucideIcons.info;
    }
  }

  Widget _buildSubtitleRow(ZaftoColors colors, Color statusColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (subtitle != null)
          Text(
            subtitle!,
            style: TextStyle(
              fontSize: 13,
              color: colors.textSecondary,
            ),
          ),
        if (subtitle != null && statusText != null)
          Text(
            ' · ',
            style: TextStyle(
              fontSize: 13,
              color: colors.textTertiary,
            ),
          ),
        if (statusText != null && showStatusBadge) ...[
          Icon(
            _getStatusIcon(),
            size: 14,
            color: statusColor,
          ),
          const SizedBox(width: 4),
          Text(
            statusText!,
            style: TextStyle(
              fontSize: 13,
              color: statusColor,
            ),
          ),
        ] else if (statusText != null) ...[
          Text(
            statusText!,
            style: TextStyle(
              fontSize: 13,
              color: colors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  bool get _hasActions =>
      onCopy != null || onAddToJob != null || (actions?.isNotEmpty ?? false);

  Widget _buildActions(ZaftoColors colors) {
    final allActions = <Widget>[];

    if (onCopy != null) {
      allActions.add(
        _ResultActionButton(
          icon: LucideIcons.copy,
          label: 'Copy',
          onTap: onCopy!,
          colors: colors,
        ),
      );
    }

    if (onAddToJob != null) {
      allActions.add(
        _ResultActionButton(
          icon: LucideIcons.plus,
          label: 'Add to Job',
          onTap: onAddToJob!,
          colors: colors,
        ),
      );
    }

    if (actions != null) {
      for (final action in actions!) {
        allActions.add(
          _ResultActionButton(
            icon: action.icon,
            label: action.label,
            onTap: action.onTap,
            colors: colors,
          ),
        );
      }
    }

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12, // Spec: 12px gap
      runSpacing: 12,
      children: allActions,
    );
  }
}

class ZaftoResultAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const ZaftoResultAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

class _ResultActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final ZaftoColors colors;

  const _ResultActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        // Spec: 20px horizontal, 10px vertical padding
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          // Spec: rgba(255,255,255,0.08)
          color: Colors.white.withOpacity(0.08),
          // Spec: borderSubtle border
          border: Border.all(color: colors.borderSubtle),
          // Spec: 20px border radius (pill)
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Spec: 16px icon
            Icon(icon, size: 16, color: colors.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact result card for displaying multiple results
///
/// Usage:
/// ```dart
/// ZaftoResultCardCompact(
///   label: 'Drop',
///   value: '3.41 V',
/// )
/// ```
class ZaftoResultCardCompact extends ConsumerWidget {
  final String label;
  final String value;
  final ResultStatus status;

  const ZaftoResultCardCompact({
    super.key,
    required this.label,
    required this.value,
    this.status = ResultStatus.neutral,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: colors.textTertiary,
          ),
        ),
      ],
    );
  }
}
