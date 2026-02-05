import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// ZAFTO Toolbox List - Design System v2.6 / Phase 0.5
///
/// A grouped list of tool categories displayed as a single card.
///
/// Structure:
/// ┌─────────────────────────────────────────┐
/// │ [Icon] Calculators · 35 NEC tools    > │
/// ├─────────────────────────────────────────┤
/// │ [Icon] Code Reference · NEC 2023     > │
/// ├─────────────────────────────────────────┤
/// │ [Icon] Tables & Data                 > │
/// ├─────────────────────────────────────────┤
/// │ [Icon] Exam Prep · 4,000+ questions  > │
/// └─────────────────────────────────────────┘
///
/// Spec: S8_02_5_DESIGN_SPEC_LOCKED.md
///
/// Usage:
/// ```dart
/// ZaftoToolboxList(
///   items: [
///     ZaftoToolboxItem(
///       icon: LucideIcons.calculator,
///       title: 'Calculators',
///       subtitle: '35 NEC tools',
///       onTap: () => _openCalculators(),
///     ),
///     // ...
///   ],
/// )
/// ```

class ZaftoToolboxItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const ZaftoToolboxItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
  });
}

class ZaftoToolboxList extends ConsumerWidget {
  /// List of items to display
  final List<ZaftoToolboxItem> items;

  /// Whether to add horizontal margin (20px)
  final bool addMargin;

  const ZaftoToolboxList({
    super.key,
    required this.items,
    this.addMargin = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    return Container(
      // Spec: margin 20px horizontal
      margin: addMargin ? const EdgeInsets.symmetric(horizontal: 20) : null,
      decoration: BoxDecoration(
        // Spec: bgElevated background
        color: colors.bgElevated,
        // Spec: borderSubtle border
        border: Border.all(color: colors.borderSubtle),
        // Spec: 16px border radius
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isLast = index == items.length - 1;
          return _ToolboxListItem(
            item: item,
            isLast: isLast,
            colors: colors,
          );
        }),
      ),
    );
  }
}

class _ToolboxListItem extends StatelessWidget {
  final ZaftoToolboxItem item;
  final bool isLast;
  final ZaftoColors colors;

  const _ToolboxListItem({
    required this.item,
    required this.isLast,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (item.onTap != null) {
          HapticFeedback.lightImpact();
          item.onTap!();
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        // Spec: padding 14px all, 16px left/right
        padding: const EdgeInsets.all(14).copyWith(left: 16, right: 16),
        decoration: BoxDecoration(
          // Spec: bottom border except last
          border: isLast
              ? null
              : Border(
                  bottom: BorderSide(color: colors.borderSubtle),
                ),
        ),
        child: Row(
          children: [
            // Icon container
            Container(
              // Spec: 36x36px, rounded 10px
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                // Spec: rgba(255,255,255,0.05)
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                // Spec: 20px icon, textSecondary
                child: Icon(
                  item.icon,
                  size: 20,
                  color: colors.textSecondary,
                ),
              ),
            ),
            // Spec: 12px gap
            const SizedBox(width: 12),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title - Spec: 15px, w500, textPrimary
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: colors.textPrimary,
                    ),
                  ),
                  if (item.subtitle != null) ...[
                    const SizedBox(height: 2),
                    // Subtitle - Spec: 12px, textTertiary
                    Text(
                      item.subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textTertiary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Trailing or chevron
            if (item.trailing != null)
              item.trailing!
            else if (item.onTap != null)
              // Spec: 16px chevron, textQuaternary
              Icon(
                LucideIcons.chevronRight,
                size: 16,
                color: colors.textQuaternary,
              ),
          ],
        ),
      ),
    );
  }
}

/// Single toolbox item (not in a list)
///
/// Usage:
/// ```dart
/// ZaftoToolboxItemWidget(
///   icon: LucideIcons.calculator,
///   title: 'Voltage Drop',
///   subtitle: 'NEC 210.19(A)',
///   onTap: () => _openVoltageDropCalc(),
/// )
/// ```
class ZaftoToolboxItemWidget extends ConsumerWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const ZaftoToolboxItemWidget({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          HapticFeedback.lightImpact();
          onTap!();
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(14).copyWith(left: 16, right: 16),
        decoration: BoxDecoration(
          color: colors.bgElevated,
          border: Border.all(color: colors.borderSubtle),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 20,
                  color: colors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: colors.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textTertiary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null)
              trailing!
            else if (onTap != null)
              Icon(
                LucideIcons.chevronRight,
                size: 16,
                color: colors.textQuaternary,
              ),
          ],
        ),
      ),
    );
  }
}
