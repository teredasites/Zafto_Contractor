import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// ZAFTO Section Header - Design System v2.6 / Phase 0.5
///
/// Section labels with optional action button.
///
/// Structure:
/// SUGGESTED FOR THIS JOB                    See all
///
/// Spec: S8_02_5_DESIGN_SPEC_LOCKED.md
///
/// Usage:
/// ```dart
/// ZaftoSectionHeader(
///   title: 'SUGGESTED FOR THIS JOB',
///   action: 'See all',
///   onActionTap: () => _openAllTools(),
/// )
/// ```

class ZaftoSectionHeader extends ConsumerWidget {
  /// The section title (will be displayed uppercase)
  final String title;

  /// Optional action text (e.g., "See all")
  final String? action;

  /// Callback when action is tapped
  final VoidCallback? onActionTap;

  /// Whether to add horizontal padding
  final bool addPadding;

  /// Whether to auto-uppercase the title
  final bool uppercase;

  const ZaftoSectionHeader({
    super.key,
    required this.title,
    this.action,
    this.onActionTap,
    this.addPadding = true,
    this.uppercase = true,
  });

  // Spec: Blue accent for action
  static const Color _blueAccent = Color(0xFF3B82F6);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    return Semantics(
      header: true,
      label: title,
      child: Padding(
        // Spec: 20px horizontal padding
        padding: addPadding
            ? const EdgeInsets.symmetric(horizontal: 20)
            : EdgeInsets.zero,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Title - Spec: 11px, w600, textTertiary, letter-spacing 1px
            ExcludeSemantics(
              child: Text(
                uppercase ? title.toUpperCase() : title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colors.textTertiary,
                  letterSpacing: 1,
                ),
              ),
            ),
            // Action - Spec: 12px, Blue
            if (action != null)
              Semantics(
                button: true,
                label: action,
                child: GestureDetector(
                  onTap: () {
                    if (onActionTap != null) {
                      HapticFeedback.lightImpact();
                      onActionTap!();
                    }
                  },
                  child: Text(
                    action!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: _blueAccent,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Section header with count badge
///
/// Usage:
/// ```dart
/// ZaftoSectionHeaderWithCount(
///   title: 'CALCULATORS',
///   count: 35,
///   action: 'See all',
/// )
/// ```
class ZaftoSectionHeaderWithCount extends ConsumerWidget {
  final String title;
  final int count;
  final String? action;
  final VoidCallback? onActionTap;
  final bool addPadding;

  const ZaftoSectionHeaderWithCount({
    super.key,
    required this.title,
    required this.count,
    this.action,
    this.onActionTap,
    this.addPadding = true,
  });

  static const Color _blueAccent = Color(0xFF3B82F6);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    return Padding(
      padding: addPadding
          ? const EdgeInsets.symmetric(horizontal: 20)
          : EdgeInsets.zero,
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colors.textTertiary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: colors.textTertiary,
              ),
            ),
          ),
          const Spacer(),
          if (action != null)
            GestureDetector(
              onTap: () {
                if (onActionTap != null) {
                  HapticFeedback.lightImpact();
                  onActionTap!();
                }
              },
              child: Text(
                action!,
                style: const TextStyle(
                  fontSize: 12,
                  color: _blueAccent,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Section header with icon
///
/// Usage:
/// ```dart
/// ZaftoSectionHeaderWithIcon(
///   icon: LucideIcons.wrench,
///   title: 'TOOLS',
/// )
/// ```
class ZaftoSectionHeaderWithIcon extends ConsumerWidget {
  final IconData icon;
  final String title;
  final String? action;
  final VoidCallback? onActionTap;
  final bool addPadding;

  const ZaftoSectionHeaderWithIcon({
    super.key,
    required this.icon,
    required this.title,
    this.action,
    this.onActionTap,
    this.addPadding = true,
  });

  static const Color _blueAccent = Color(0xFF3B82F6);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    return Padding(
      padding: addPadding
          ? const EdgeInsets.symmetric(horizontal: 20)
          : EdgeInsets.zero,
      child: Row(
        children: [
          Icon(
            icon,
            size: 14,
            color: colors.textTertiary,
          ),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colors.textTertiary,
              letterSpacing: 1,
            ),
          ),
          const Spacer(),
          if (action != null)
            GestureDetector(
              onTap: () {
                if (onActionTap != null) {
                  HapticFeedback.lightImpact();
                  onActionTap!();
                }
              },
              child: Text(
                action!,
                style: const TextStyle(
                  fontSize: 12,
                  color: _blueAccent,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
