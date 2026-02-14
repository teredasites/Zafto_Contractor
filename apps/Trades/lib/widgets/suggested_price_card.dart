// ZAFTO Suggested Price Card — Widget for estimate screens
// Shows smart pricing suggestion with factor breakdown, accept/override.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/zafto_colors.dart';
import '../theme/theme_provider.dart';
import '../models/pricing_suggestion.dart';

class SuggestedPriceCard extends ConsumerWidget {
  final PricingSuggestion? suggestion;
  final VoidCallback? onAccept;
  final VoidCallback? onDismiss;
  final bool isLoading;

  const SuggestedPriceCard({
    super.key,
    this.suggestion,
    this.onAccept,
    this.onDismiss,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    if (isLoading) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: colors.accentPrimary),
            ),
            const SizedBox(width: 12),
            Text('Calculating smart price...', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
          ],
        ),
      );
    }

    if (suggestion == null) return const SizedBox.shrink();

    final s = suggestion!;
    final isIncrease = s.isIncrease;
    final adjustmentPct = s.totalAdjustmentPct;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isIncrease
              ? colors.accentPrimary.withValues(alpha: 0.3)
              : colors.success.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(LucideIcons.sparkles, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Smart Price Suggestion',
                style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (isIncrease ? colors.accentPrimary : colors.success).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${adjustmentPct >= 0 ? '+' : ''}${adjustmentPct.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: isIncrease ? colors.accentPrimary : colors.success,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Price comparison
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Base Price', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
                    Text(
                      '\$${s.basePrice.toStringAsFixed(2)}',
                      style: TextStyle(color: colors.textSecondary, fontSize: 16, decoration: TextDecoration.lineThrough),
                    ),
                  ],
                ),
              ),
              Icon(LucideIcons.arrowRight, color: colors.textTertiary, size: 16),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Suggested', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
                    Text(
                      '\$${s.suggestedPrice.toStringAsFixed(2)}',
                      style: TextStyle(color: colors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Factors
          if (s.factorsApplied.isNotEmpty) ...[
            Divider(color: colors.bgBase, height: 1),
            const SizedBox(height: 10),
            ...s.factorsApplied.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(
                    f.isIncrease ? LucideIcons.arrowUpRight : LucideIcons.arrowDownRight,
                    color: f.isIncrease ? colors.warning : colors.success,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(f.label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                  ),
                  Text(
                    '${f.amount >= 0 ? '+' : ''}\$${f.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: f.isIncrease ? colors.warning : colors.success,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )),
          ],

          // Actions
          if (onAccept != null || onDismiss != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (onAccept != null)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onAccept,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.accentPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Accept', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ),
                if (onAccept != null && onDismiss != null) const SizedBox(width: 8),
                if (onDismiss != null)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onDismiss,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.textSecondary,
                        side: BorderSide(color: colors.textTertiary.withValues(alpha: 0.3)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Override', style: TextStyle(fontSize: 13)),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
