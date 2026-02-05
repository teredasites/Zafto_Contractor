import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Conduit Bend Multipliers Table - Design System v2.6
class ConduitBendMultipliersScreen extends ConsumerWidget {
  const ConduitBendMultipliersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Conduit Bend Multipliers', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOffsetMultipliers(colors),
            const SizedBox(height: 16),
            _buildShrinkage(colors),
            const SizedBox(height: 16),
            _buildSaddleMultipliers(colors),
            const SizedBox(height: 16),
            _buildKickMultipliers(colors),
            const SizedBox(height: 16),
            _buildFormulas(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildOffsetMultipliers(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.move, color: colors.accentPrimary, size: 20),
            const SizedBox(width: 8),
            Text('OFFSET MULTIPLIERS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 8),
          Text('Distance between bends = Offset × Multiplier', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(border: Border.all(color: colors.borderSubtle), borderRadius: BorderRadius.circular(8)),
            child: Column(
              children: [
                _headerRow(['Bend Angle', 'Multiplier', 'Shrink/inch'], colors),
                _dataRow(['10°', '6.0', '1/16"'], colors),
                _dataRow(['15°', '4.0', '1/8"'], colors),
                _dataRow(['22.5°', '2.6', '3/16"'], colors),
                _dataRow(['30°', '2.0', '1/4"'], colors),
                _dataRow(['45°', '1.4', '3/8"'], colors),
                _dataRow(['60°', '1.2', '1/2"'], colors),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Example: 6" offset at 30°', style: TextStyle(color: colors.accentPrimary, fontFamily: 'monospace', fontSize: 11)),
                Text('Distance = 6" × 2.0 = 12"', style: TextStyle(color: colors.textSecondary, fontFamily: 'monospace', fontSize: 11)),
                Text('Shrink = 6" × 1/4" = 1.5"', style: TextStyle(color: colors.textSecondary, fontFamily: 'monospace', fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShrinkage(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.accentWarning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.accentWarning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.arrowDownFromLine, color: colors.accentWarning, size: 18),
            const SizedBox(width: 8),
            Text('SHRINKAGE (TAKE-UP)', style: TextStyle(color: colors.accentWarning, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 8),
          Text(
            'Shrink = amount conduit "shortens" after bending.\n'
            'Add shrink to your first mark to compensate.\n\n'
            'Total Shrink = Offset Height × Shrink per inch',
            style: TextStyle(color: colors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 8),
          _shrinkRow('30° offset', '1/4" per inch of offset', colors),
          _shrinkRow('45° offset', '3/8" per inch of offset', colors),
          _shrinkRow('90° stub', 'Deduct (marked on bender)', colors),
        ],
      ),
    );
  }

  Widget _shrinkRow(String type, String value, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(type, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 11))),
          Expanded(child: Text(value, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _buildSaddleMultipliers(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('3-BEND SADDLE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Text('Center bend = 2× outer bends', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(border: Border.all(color: colors.borderSubtle), borderRadius: BorderRadius.circular(8)),
            child: Column(
              children: [
                _headerRow(['Center Bend', 'Outer Bends', 'Multiplier'], colors),
                _dataRow(['22.5°', '11.25°', '2.5'], colors),
                _dataRow(['30°', '15°', '2.0'], colors),
                _dataRow(['45°', '22.5°', '1.4'], colors),
                _dataRow(['60°', '30°', '1.2'], colors),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text('Distance from center mark = Obstruction height × Multiplier', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildKickMultipliers(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('KICK (90° WITH RISE)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(border: Border.all(color: colors.borderSubtle), borderRadius: BorderRadius.circular(8)),
            child: Column(
              children: [
                _headerRow(['Kick Angle', 'Travel Multiplier', ''], colors),
                _dataRow(['10°', '6.0', ''], colors),
                _dataRow(['15°', '4.0', ''], colors),
                _dataRow(['22.5°', '2.6', ''], colors),
                _dataRow(['30°', '2.0', ''], colors),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text('Travel = Kick height × Multiplier', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildFormulas(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.accentInfo.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.accentInfo.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.calculator, color: colors.accentInfo, size: 18),
            const SizedBox(width: 8),
            Text('QUICK FORMULAS', style: TextStyle(color: colors.accentInfo, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 10),
          _formulaRow('Offset Distance', 'Offset × Multiplier', colors),
          _formulaRow('Shrink', 'Offset × Shrink/inch', colors),
          _formulaRow('Saddle marks', 'Height × Multiplier', colors),
          _formulaRow('90° stub', 'Stub - Deduct', colors),
          _formulaRow('Back-to-back', '1st stub + 2nd stub - gain', colors),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(6)),
            child: Text(
              'Memory trick for 30° offset:\n'
              '• Multiplier = 2\n'
              '• Shrink = 1/4" per inch\n'
              'Most common bend - memorize these!',
              style: TextStyle(color: colors.accentPrimary, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _formulaRow(String name, String formula, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 110, child: Text(name, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 11))),
          Expanded(child: Text(formula, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _headerRow(List<String> headers, ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: colors.accentPrimary.withValues(alpha: 0.2),
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(7), topRight: Radius.circular(7)),
      ),
      child: Row(
        children: headers.map((h) => Expanded(
          child: Text(h, textAlign: TextAlign.center, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.bold, fontSize: 10)),
        )).toList(),
      ),
    );
  }

  Widget _dataRow(List<String> values, ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: colors.borderSubtle, width: 0.5))),
      child: Row(
        children: values.asMap().entries.map((e) => Expanded(
          child: Text(e.value, textAlign: TextAlign.center, style: TextStyle(color: e.key == 0 ? colors.accentPrimary : colors.textSecondary, fontWeight: e.key == 0 ? FontWeight.bold : FontWeight.normal, fontSize: 11)),
        )).toList(),
      ),
    );
  }
}
