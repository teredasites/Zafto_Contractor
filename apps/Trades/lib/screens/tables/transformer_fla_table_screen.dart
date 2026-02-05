import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Transformer FLA Tables - Design System v2.6
class TransformerFlaTableScreen extends ConsumerWidget {
  const TransformerFlaTableScreen({super.key});

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
        title: Text('Transformer FLA Tables', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFormula(colors),
            const SizedBox(height: 16),
            _buildSinglePhaseTable(colors),
            const SizedBox(height: 16),
            _buildThreePhaseTable(colors),
            const SizedBox(height: 16),
            _buildOCPD(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildFormula(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.accentPrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.calculator, color: colors.accentPrimary, size: 18),
            const SizedBox(width: 8),
            Text('TRANSFORMER FLA FORMULAS', style: TextStyle(color: colors.accentPrimary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Single-Phase:', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12)),
                Text('FLA = kVA × 1000 / Voltage', style: TextStyle(color: colors.accentPrimary, fontFamily: 'monospace', fontSize: 13)),
                const SizedBox(height: 8),
                Text('Three-Phase:', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12)),
                Text('FLA = kVA × 1000 / (Voltage × 1.732)', style: TextStyle(color: colors.accentPrimary, fontFamily: 'monospace', fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSinglePhaseTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SINGLE-PHASE TRANSFORMER FLA', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          _tableHeader(['kVA', '120V', '240V', '277V', '480V'], colors),
          _tableRow(['1', '8.3', '4.2', '3.6', '2.1'], colors),
          _tableRow(['2', '16.7', '8.3', '7.2', '4.2'], colors),
          _tableRow(['3', '25.0', '12.5', '10.8', '6.3'], colors),
          _tableRow(['5', '41.7', '20.8', '18.1', '10.4'], colors),
          _tableRow(['7.5', '62.5', '31.3', '27.1', '15.6'], colors),
          _tableRow(['10', '83.3', '41.7', '36.1', '20.8'], colors),
          _tableRow(['15', '125', '62.5', '54.2', '31.3'], colors),
          _tableRow(['25', '208', '104', '90.3', '52.1'], colors),
          _tableRow(['37.5', '313', '156', '135', '78.1'], colors),
          _tableRow(['50', '417', '208', '181', '104'], colors),
          _tableRow(['75', '625', '313', '271', '156'], colors),
          _tableRow(['100', '833', '417', '361', '208'], colors),
        ],
      ),
    );
  }

  Widget _buildThreePhaseTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('THREE-PHASE TRANSFORMER FLA', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          _tableHeader(['kVA', '208V', '240V', '480V', '600V'], colors),
          _tableRow(['3', '8.3', '7.2', '3.6', '2.9'], colors),
          _tableRow(['6', '16.7', '14.4', '7.2', '5.8'], colors),
          _tableRow(['9', '25.0', '21.7', '10.8', '8.7'], colors),
          _tableRow(['15', '41.7', '36.1', '18.0', '14.4'], colors),
          _tableRow(['30', '83.3', '72.2', '36.1', '28.9'], colors),
          _tableRow(['45', '125', '108', '54.2', '43.3'], colors),
          _tableRow(['75', '208', '180', '90.2', '72.2'], colors),
          _tableRow(['112.5', '312', '271', '135', '108'], colors),
          _tableRow(['150', '417', '361', '180', '144'], colors),
          _tableRow(['225', '625', '541', '271', '217'], colors),
          _tableRow(['300', '833', '722', '361', '289'], colors),
          _tableRow(['500', '1388', '1203', '601', '481'], colors),
          _tableRow(['750', '2082', '1804', '902', '722'], colors),
          _tableRow(['1000', '2776', '2406', '1203', '962'], colors),
        ],
      ),
    );
  }

  Widget _tableHeader(List<String> cells, ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: colors.accentPrimary.withValues(alpha: 0.2),
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
      ),
      child: Row(
        children: cells.map((c) => Expanded(
          child: Text(c, textAlign: TextAlign.center, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.bold, fontSize: 11)),
        )).toList(),
      ),
    );
  }

  Widget _tableRow(List<String> cells, ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: colors.borderSubtle, width: 0.5))),
      child: Row(
        children: cells.asMap().entries.map((e) => Expanded(
          child: Text(e.value, textAlign: TextAlign.center, style: TextStyle(color: e.key == 0 ? colors.textPrimary : colors.textSecondary, fontWeight: e.key == 0 ? FontWeight.bold : FontWeight.normal, fontSize: 11)),
        )).toList(),
      ),
    );
  }

  Widget _buildOCPD(ZaftoColors colors) {
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
            Icon(LucideIcons.shield, color: colors.accentInfo, size: 18),
            const SizedBox(width: 8),
            Text('OCPD SIZING (NEC 450.3)', style: TextStyle(color: colors.accentInfo, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Text(
            'Primary: 125% of rated primary current\n'
            'Secondary: 125% of rated secondary current\n\n'
            'If 125% does not correspond to standard size, next higher standard size permitted.',
            style: TextStyle(color: colors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
