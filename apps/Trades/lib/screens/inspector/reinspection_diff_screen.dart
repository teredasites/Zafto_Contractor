import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:zafto/theme/zafto_colors.dart';
import 'package:zafto/theme/theme_provider.dart';
import 'package:zafto/models/inspection.dart';
import 'package:zafto/services/inspection_service.dart';

// ============================================================
// Re-Inspection Diff Screen
//
// Side-by-side comparison of original vs re-inspection.
// Shows what changed: items that went from fail→pass, etc.
// Groups by section, highlights changes.
// ============================================================

class ReinspectionDiffScreen extends ConsumerWidget {
  final PmInspection original;
  final PmInspection reinspection;

  const ReinspectionDiffScreen({
    super.key,
    required this.original,
    required this.reinspection,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);
    final origItemsAsync = ref.watch(inspectionItemsProvider(original.id));
    final reItemsAsync = ref.watch(inspectionItemsProvider(reinspection.id));

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
          'Inspection Comparison',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
      ),
      body: origItemsAsync.when(
        loading: () =>
            Center(child: CircularProgressIndicator(color: colors.accentPrimary)),
        error: (e, _) => _buildError(colors, 'Failed to load original items'),
        data: (origItems) => reItemsAsync.when(
          loading: () => Center(
              child: CircularProgressIndicator(color: colors.accentPrimary)),
          error: (e, _) =>
              _buildError(colors, 'Failed to load re-inspection items'),
          data: (reItems) =>
              _buildDiffBody(colors, origItems, reItems),
        ),
      ),
    );
  }

  Widget _buildDiffBody(ZaftoColors colors, List<PmInspectionItem> origItems,
      List<PmInspectionItem> reItems) {
    // Build lookup: area+itemName → condition for re-inspection
    final reMap = <String, PmInspectionItem>{};
    for (final item in reItems) {
      reMap['${item.area}::${item.itemName}'] = item;
    }

    // Group original items by area
    final sections = <String, List<PmInspectionItem>>{};
    for (final item in origItems) {
      sections.putIfAbsent(item.area, () => []).add(item);
    }

    // Count changes
    var improved = 0;
    var regressed = 0;
    var unchanged = 0;

    for (final item in origItems) {
      final reItem = reMap['${item.area}::${item.itemName}'];
      if (reItem == null) {
        unchanged++;
        continue;
      }
      final origScore = _conditionScore(item.condition);
      final reScore = _conditionScore(reItem.condition);
      if (reScore > origScore) {
        improved++;
      } else if (reScore < origScore) {
        regressed++;
      } else {
        unchanged++;
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        // Score comparison header
        _buildScoreComparison(colors),
        const SizedBox(height: 16),

        // Change summary
        Row(
          children: [
            _buildChangeBadge(colors, '$improved Improved',
                colors.accentSuccess, LucideIcons.trendingUp),
            const SizedBox(width: 8),
            _buildChangeBadge(colors, '$regressed Regressed',
                colors.accentError, LucideIcons.trendingDown),
            const SizedBox(width: 8),
            _buildChangeBadge(colors, '$unchanged Same',
                colors.textTertiary, LucideIcons.minus),
          ],
        ),
        const SizedBox(height: 20),

        // Per-section diff
        ...sections.entries.map((entry) {
          final area = entry.key;
          final items = entry.value;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Text(
                  area.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: colors.textTertiary,
                    letterSpacing: 1,
                  ),
                ),
              ),
              ...items.map((origItem) {
                final reItem =
                    reMap['${origItem.area}::${origItem.itemName}'];
                return _buildDiffRow(colors, origItem, reItem);
              }),
              Divider(color: colors.borderSubtle, height: 20),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildScoreComparison(ZaftoColors colors) {
    final origScore = original.score ?? 0;
    final reScore = reinspection.score ?? 0;
    final diff = reScore - origScore;
    final improved = diff > 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        children: [
          // Original score
          _buildScoreCircle(colors, origScore, 'Original'),
          const SizedBox(width: 16),

          // Arrow + diff
          Expanded(
            child: Column(
              children: [
                Icon(
                  improved ? LucideIcons.arrowRight : LucideIcons.arrowRight,
                  size: 24,
                  color: colors.textQuaternary,
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (diff > 0
                            ? colors.accentSuccess
                            : diff < 0
                                ? colors.accentError
                                : colors.textTertiary)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${diff > 0 ? '+' : ''}$diff',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: diff > 0
                          ? colors.accentSuccess
                          : diff < 0
                              ? colors.accentError
                              : colors.textTertiary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Re-inspection score
          _buildScoreCircle(colors, reScore, 'Re-Inspect'),
        ],
      ),
    );
  }

  Widget _buildScoreCircle(ZaftoColors colors, int score, String label) {
    final passed = score >= InspectionService.passThreshold;
    final color = passed ? colors.accentSuccess : colors.accentError;

    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.1),
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: Text(
              '$score',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: colors.textTertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildChangeBadge(
      ZaftoColors colors, String label, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiffRow(
      ZaftoColors colors, PmInspectionItem origItem, PmInspectionItem? reItem) {
    final origColor = _conditionColor(origItem.condition, colors);
    final reColor =
        reItem != null ? _conditionColor(reItem.condition, colors) : colors.textQuaternary;
    final changed = reItem != null && origItem.condition != reItem.condition;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: changed
            ? colors.accentPrimary.withValues(alpha: 0.04)
            : colors.bgElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: changed
              ? colors.accentPrimary.withValues(alpha: 0.2)
              : colors.borderSubtle,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              origItem.itemName,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: colors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Original condition
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: origColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _conditionLabel(origItem.condition),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: origColor,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Icon(
              LucideIcons.arrowRight,
              size: 12,
              color: colors.textQuaternary,
            ),
          ),
          // Re-inspection condition
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: reColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              reItem != null ? _conditionLabel(reItem.condition) : '—',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: reColor,
              ),
            ),
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

  int _conditionScore(ItemCondition c) {
    switch (c) {
      case ItemCondition.excellent:
        return 5;
      case ItemCondition.good:
        return 4;
      case ItemCondition.fair:
        return 3;
      case ItemCondition.poor:
        return 2;
      case ItemCondition.damaged:
        return 1;
      case ItemCondition.missing:
        return 0;
    }
  }

  Color _conditionColor(ItemCondition c, ZaftoColors colors) {
    switch (c) {
      case ItemCondition.excellent:
      case ItemCondition.good:
        return colors.accentSuccess;
      case ItemCondition.fair:
        return colors.accentWarning;
      case ItemCondition.poor:
      case ItemCondition.damaged:
        return colors.accentError;
      case ItemCondition.missing:
        return colors.textTertiary;
    }
  }

  String _conditionLabel(ItemCondition c) {
    switch (c) {
      case ItemCondition.excellent:
        return 'Excellent';
      case ItemCondition.good:
        return 'Pass';
      case ItemCondition.fair:
        return 'Cond.';
      case ItemCondition.poor:
        return 'Poor';
      case ItemCondition.damaged:
        return 'Fail';
      case ItemCondition.missing:
        return 'N/A';
    }
  }
}
