import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// ZAFTO Quick Tools - Design System v2.6 / Phase 0.5
///
/// Horizontal scrolling row of suggested tools.
///
/// Structure:
/// [Load Calc] [Wire Size] [Panel Sched] [Conduit] ...
///
/// Each item is a 72x72px card with icon and label.
///
/// Spec: S8_02_5_DESIGN_SPEC_LOCKED.md
///
/// Usage:
/// ```dart
/// ZaftoQuickTools(
///   tools: [
///     ZaftoQuickToolItem(icon: LucideIcons.zap, label: 'Load Calc', onTap: () => ...),
///     ZaftoQuickToolItem(icon: LucideIcons.gitCommitHorizontal, label: 'Wire Size', onTap: () => ...),
///   ],
/// )
/// ```

class ZaftoQuickToolItem {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? iconColor;

  const ZaftoQuickToolItem({
    required this.icon,
    required this.label,
    this.onTap,
    this.iconColor,
  });
}

class ZaftoQuickTools extends ConsumerWidget {
  /// List of tools to display
  final List<ZaftoQuickToolItem> tools;

  /// Whether to add horizontal padding
  final bool addPadding;

  const ZaftoQuickTools({
    super.key,
    required this.tools,
    this.addPadding = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      // Spec: 20px horizontal padding
      padding: addPadding ? const EdgeInsets.symmetric(horizontal: 20) : null,
      child: Row(
        children: tools.map((tool) {
          return _QuickToolCard(
            tool: tool,
            colors: colors,
          );
        }).toList(),
      ),
    );
  }
}

class _QuickToolCard extends StatelessWidget {
  final ZaftoQuickToolItem tool;
  final ZaftoColors colors;

  const _QuickToolCard({
    required this.tool,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (tool.onTap != null) {
          HapticFeedback.lightImpact();
          tool.onTap!();
        }
      },
      child: Container(
        // Spec: 72x72px
        width: 72,
        height: 72,
        // Spec: margin right 10px
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          // Spec: bgElevated background
          color: colors.bgElevated,
          // Spec: borderSubtle border
          border: Border.all(color: colors.borderSubtle),
          // Spec: 16px border radius
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Spec: 20px icon, textSecondary
            Icon(
              tool.icon,
              size: 20,
              color: tool.iconColor ?? colors.textSecondary,
            ),
            // Spec: 6px gap
            const SizedBox(height: 6),
            // Spec: 10px, w500, textTertiary
            Text(
              tool.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: colors.textTertiary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Quick tools row with "more" button at the end
///
/// Usage:
/// ```dart
/// ZaftoQuickToolsWithMore(
///   tools: [...],
///   onMoreTap: () => _openAllTools(),
/// )
/// ```
class ZaftoQuickToolsWithMore extends ConsumerWidget {
  final List<ZaftoQuickToolItem> tools;
  final VoidCallback? onMoreTap;
  final bool addPadding;

  const ZaftoQuickToolsWithMore({
    super.key,
    required this.tools,
    this.onMoreTap,
    this.addPadding = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: addPadding ? const EdgeInsets.symmetric(horizontal: 20) : null,
      child: Row(
        children: [
          ...tools.map((tool) => _QuickToolCard(tool: tool, colors: colors)),
          // More button
          if (onMoreTap != null) _MoreButton(onTap: onMoreTap!, colors: colors),
        ],
      ),
    );
  }
}

class _MoreButton extends StatelessWidget {
  final VoidCallback onTap;
  final ZaftoColors colors;

  const _MoreButton({
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
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: colors.bgElevated,
          border: Border.all(
            color: colors.borderSubtle,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.more_horiz,
                size: 16,
                color: colors.textTertiary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'More',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: colors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Large quick tools for featured tools section
///
/// Usage:
/// ```dart
/// ZaftoQuickToolsLarge(
///   tools: [...],
/// )
/// ```
class ZaftoQuickToolsLarge extends ConsumerWidget {
  final List<ZaftoQuickToolItem> tools;
  final bool addPadding;

  const ZaftoQuickToolsLarge({
    super.key,
    required this.tools,
    this.addPadding = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: addPadding ? const EdgeInsets.symmetric(horizontal: 20) : null,
      child: Row(
        children: tools.map((tool) {
          return _LargeToolCard(tool: tool, colors: colors);
        }).toList(),
      ),
    );
  }
}

class _LargeToolCard extends StatelessWidget {
  final ZaftoQuickToolItem tool;
  final ZaftoColors colors;

  const _LargeToolCard({
    required this.tool,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (tool.onTap != null) {
          HapticFeedback.lightImpact();
          tool.onTap!();
        }
      },
      child: Container(
        width: 100,
        height: 100,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.bgElevated,
          border: Border.all(color: colors.borderSubtle),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Icon(
                  tool.icon,
                  size: 20,
                  color: tool.iconColor ?? colors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              tool.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: colors.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
