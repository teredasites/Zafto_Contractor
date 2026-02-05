import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// ZAFTO Tool Card - Design System v2.6 / Phase 0.5
///
/// Grid card for individual tools displayed in 2-column layout.
///
/// Structure:
/// ┌─────────────────────┐
/// │ [Icon Container]    │
/// │                     │
/// │ Title               │
/// │ Subtitle            │
/// └─────────────────────┘
///
/// Spec: S8_02_5_DESIGN_SPEC_LOCKED.md
///
/// Usage:
/// ```dart
/// ZaftoToolCard(
///   icon: LucideIcons.zap,
///   title: 'Voltage Drop',
///   subtitle: 'NEC 210.19(A)',
///   onTap: () => _openVoltageDropCalc(),
/// )
/// ```
///
/// For grid layout use:
/// ```dart
/// ZaftoToolCardGrid(
///   items: [
///     ZaftoToolCardItem(icon: LucideIcons.zap, title: 'Voltage Drop', ...),
///     // ...
///   ],
/// )
/// ```

class ZaftoToolCardItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color? iconColor;

  const ZaftoToolCardItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.iconColor,
  });
}

class ZaftoToolCard extends ConsumerWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color? iconColor;

  const ZaftoToolCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.iconColor,
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
      child: Container(
        // Spec: 16px padding
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          // Spec: bgElevated background
          color: colors.bgElevated,
          // Spec: borderSubtle border
          border: Border.all(color: colors.borderSubtle),
          // Spec: 14px border radius
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon container
            Container(
              // Spec: 40x40px, rounded 10px
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                // Spec: rgba(255,255,255,0.05)
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                // Spec: 20px icon, textSecondary
                child: Icon(
                  icon,
                  size: 20,
                  color: iconColor ?? colors.textSecondary,
                ),
              ),
            ),
            // Spec: 12px gap
            const SizedBox(height: 12),
            // Title - Spec: 14px, w500, textPrimary
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colors.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitle != null) ...[
              // Spec: 4px gap
              const SizedBox(height: 4),
              // Subtitle - Spec: 11px, textTertiary
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 11,
                  color: colors.textTertiary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Grid layout for tool cards
///
/// Spec: 2 columns, 10px spacing, aspect ratio 1.1
class ZaftoToolCardGrid extends ConsumerWidget {
  final List<ZaftoToolCardItem> items;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const ZaftoToolCardGrid({
    super.key,
    required this.items,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GridView.builder(
      // Spec: 20px horizontal padding
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 20),
      shrinkWrap: shrinkWrap,
      physics: physics,
      // Spec: 2 columns, 10px spacing, aspect ratio 1.1
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.1,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return ZaftoToolCard(
          icon: item.icon,
          title: item.title,
          subtitle: item.subtitle,
          onTap: item.onTap,
          iconColor: item.iconColor,
        );
      },
    );
  }
}

/// Sliver version for use in CustomScrollView
class ZaftoToolCardSliverGrid extends ConsumerWidget {
  final List<ZaftoToolCardItem> items;
  final EdgeInsetsGeometry? padding;

  const ZaftoToolCardSliverGrid({
    super.key,
    required this.items,
    this.padding,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SliverPadding(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.1,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = items[index];
            return ZaftoToolCard(
              icon: item.icon,
              title: item.title,
              subtitle: item.subtitle,
              onTap: item.onTap,
              iconColor: item.iconColor,
            );
          },
          childCount: items.length,
        ),
      ),
    );
  }
}
