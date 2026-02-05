import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// ZAFTO Category Pills - Design System v2.6 / Phase 0.5
///
/// Horizontal scrolling filter chips for categories.
///
/// Structure:
/// [All] [Wire & Cable] [Load] [Motor] [Conduit] ...
///
/// Spec: S8_02_5_DESIGN_SPEC_LOCKED.md
///
/// Usage:
/// ```dart
/// ZaftoCategoryPills(
///   categories: ['All', 'Wire & Cable', 'Load', 'Motor', 'Conduit'],
///   selectedIndex: _selectedCategory,
///   onChanged: (index) => setState(() => _selectedCategory = index),
/// )
/// ```

class ZaftoCategoryPills extends ConsumerWidget {
  /// List of category labels
  final List<String> categories;

  /// Currently selected index
  final int selectedIndex;

  /// Callback when selection changes
  final ValueChanged<int> onChanged;

  /// Whether to add horizontal padding
  final bool addPadding;

  const ZaftoCategoryPills({
    super.key,
    required this.categories,
    required this.selectedIndex,
    required this.onChanged,
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
        children: List.generate(categories.length, (index) {
          final isSelected = index == selectedIndex;
          return _CategoryPill(
            label: categories[index],
            isSelected: isSelected,
            onTap: () {
              HapticFeedback.selectionClick();
              onChanged(index);
            },
            colors: colors,
          );
        }),
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final ZaftoColors colors;

  const _CategoryPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        // Spec: margin right 8px
        margin: const EdgeInsets.only(right: 8),
        // Spec: 14px horizontal, 8px vertical padding
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          // Active: accentPrimary, Inactive: bgElevated
          color: isSelected ? colors.accentPrimary : colors.bgElevated,
          // Inactive: borderSubtle border
          border: isSelected ? null : Border.all(color: colors.borderSubtle),
          // Spec: 20px border radius (pill)
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          // Spec: 12px, w500
          // Active: black, Inactive: textSecondary
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.black : colors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// Category pills with icons
///
/// Usage:
/// ```dart
/// ZaftoCategoryPillsWithIcons(
///   categories: [
///     ZaftoCategoryItem(label: 'All', icon: LucideIcons.grid),
///     ZaftoCategoryItem(label: 'Wire', icon: LucideIcons.gitCommitHorizontal),
///   ],
///   selectedIndex: 0,
///   onChanged: (index) => setState(() => _selectedCategory = index),
/// )
/// ```
class ZaftoCategoryItem {
  final String label;
  final IconData? icon;

  const ZaftoCategoryItem({
    required this.label,
    this.icon,
  });
}

class ZaftoCategoryPillsWithIcons extends ConsumerWidget {
  final List<ZaftoCategoryItem> categories;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final bool addPadding;

  const ZaftoCategoryPillsWithIcons({
    super.key,
    required this.categories,
    required this.selectedIndex,
    required this.onChanged,
    this.addPadding = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: addPadding ? const EdgeInsets.symmetric(horizontal: 20) : null,
      child: Row(
        children: List.generate(categories.length, (index) {
          final item = categories[index];
          final isSelected = index == selectedIndex;
          return _CategoryPillWithIcon(
            item: item,
            isSelected: isSelected,
            onTap: () {
              HapticFeedback.selectionClick();
              onChanged(index);
            },
            colors: colors,
          );
        }),
      ),
    );
  }
}

class _CategoryPillWithIcon extends StatelessWidget {
  final ZaftoCategoryItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final ZaftoColors colors;

  const _CategoryPillWithIcon({
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? colors.accentPrimary : colors.bgElevated,
          border: isSelected ? null : Border.all(color: colors.borderSubtle),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (item.icon != null) ...[
              Icon(
                item.icon,
                size: 14,
                color: isSelected ? Colors.black : colors.textSecondary,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              item.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.black : colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Multi-select category pills
///
/// Usage:
/// ```dart
/// ZaftoCategoryPillsMulti(
///   categories: ['Wire', 'Conduit', 'Box', 'Motor'],
///   selectedIndices: {0, 2},
///   onChanged: (indices) => setState(() => _selected = indices),
/// )
/// ```
class ZaftoCategoryPillsMulti extends ConsumerWidget {
  final List<String> categories;
  final Set<int> selectedIndices;
  final ValueChanged<Set<int>> onChanged;
  final bool addPadding;

  const ZaftoCategoryPillsMulti({
    super.key,
    required this.categories,
    required this.selectedIndices,
    required this.onChanged,
    this.addPadding = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: addPadding ? const EdgeInsets.symmetric(horizontal: 20) : null,
      child: Row(
        children: List.generate(categories.length, (index) {
          final isSelected = selectedIndices.contains(index);
          return _CategoryPill(
            label: categories[index],
            isSelected: isSelected,
            onTap: () {
              HapticFeedback.selectionClick();
              final newSet = Set<int>.from(selectedIndices);
              if (isSelected) {
                newSet.remove(index);
              } else {
                newSet.add(index);
              }
              onChanged(newSet);
            },
            colors: colors,
          );
        }),
      ),
    );
  }
}
