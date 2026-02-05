import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// 3-Phase Power Basics Diagram - Design System v2.6
class ThreePhaseBasicsScreen extends ConsumerWidget {
  const ThreePhaseBasicsScreen({super.key});

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
        title: Text('3-Phase Power Basics', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWhatIs3Phase(colors),
            const SizedBox(height: 16),
            _buildWyeDelta(colors),
            const SizedBox(height: 16),
            _buildVoltages(colors),
            const SizedBox(height: 16),
            _buildColorCodes(colors),
            const SizedBox(height: 16),
            _buildFormulas(colors),
            const SizedBox(height: 16),
            _buildPanelConfig(colors),
            const SizedBox(height: 16),
            _buildCodeReference(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildWhatIs3Phase(ZaftoColors colors) {
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
            Icon(LucideIcons.activity, color: colors.accentPrimary, size: 20),
            const SizedBox(width: 8),
            Text('What is 3-Phase Power?', style: TextStyle(color: colors.accentPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 12),
          Text(
            'Three separate AC voltages, 120 degrees apart. Provides more power with smaller conductors, '
            'constant power delivery (not pulsing like single-phase), and ability to run large motors smoothly.',
            style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('Phase A ~~~~', colors.accentError),
                _diagramLine('Phase B   ~~~~  (120 deg behind A)', colors.accentInfo),
                _diagramLine('Phase C     ~~~~  (240 deg behind A)', colors.accentWarning),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _diagramLine(String text, Color color) {
    return Text(text, style: TextStyle(color: color, fontFamily: 'monospace', fontSize: 11));
  }

  Widget _buildWyeDelta(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('WYE (Y) vs DELTA (triangle) CONFIGURATIONS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _configBox('WYE (Y)', '    A\n    |\nB---*---C\n    |\n    N', 'Has Neutral', colors.accentSuccess, colors)),
            const SizedBox(width: 12),
            Expanded(child: _configBox('DELTA', '    A\n   / \\\n  /   \\\n B-----C', 'No Neutral', colors.accentWarning, colors)),
          ]),
          const SizedBox(height: 12),
          Text('Wye: Has neutral, can provide 120V and 208V', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 4),
          Text('Delta: No neutral, 240V only (or high-leg with tap)', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _configBox(String title, String diagram, String note, Color noteColor, ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Text(title, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w700, fontSize: 12)),
        const SizedBox(height: 8),
        Text(diagram, style: TextStyle(color: colors.textTertiary, fontFamily: 'monospace', fontSize: 10)),
        const SizedBox(height: 8),
        Text(note, style: TextStyle(color: noteColor, fontSize: 11, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _buildVoltages(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('COMMON 3-PHASE VOLTAGES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(border: Border.all(color: colors.borderSubtle), borderRadius: BorderRadius.circular(12)),
            child: Column(children: [
              _tableHeader(['System', 'L-N', 'L-L', 'Type'], colors),
              _tableRow(['120/208V', '120V', '208V', 'Wye'], colors),
              _tableRow(['277/480V', '277V', '480V', 'Wye'], colors),
              _tableRow(['120/240V', '120V*', '240V', 'Delta (high-leg)'], colors),
              _tableRow(['240V Delta', 'N/A', '240V', 'Delta'], colors),
              _tableRow(['480V Delta', 'N/A', '480V', 'Delta'], colors, isLast: true),
            ]),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.accentWarning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              Icon(LucideIcons.alertTriangle, color: colors.accentWarning, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text('*High-leg delta: One phase to neutral = 208V (danger!)', style: TextStyle(color: colors.accentWarning, fontSize: 11))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _tableHeader(List<String> headers, ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: colors.accentPrimary.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(11), topRight: Radius.circular(11)),
      ),
      child: Row(children: headers.map((h) => Expanded(child: Text(h, textAlign: TextAlign.center, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 10)))).toList()),
    );
  }

  Widget _tableRow(List<String> values, ZaftoColors colors, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(border: isLast ? null : Border(bottom: BorderSide(color: colors.borderSubtle, width: 0.5))),
      child: Row(children: values.asMap().entries.map((e) => Expanded(child: Text(e.value, textAlign: TextAlign.center, style: TextStyle(color: e.key == 0 ? colors.textPrimary : colors.textSecondary, fontWeight: e.key == 0 ? FontWeight.w600 : FontWeight.w400, fontSize: 11)))).toList()),
    );
  }

  Widget _buildColorCodes(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('WIRE COLOR CODES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Text('120/208V or 120/240V:', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 6),
          _colorRow('Phase A', 'Black', Colors.grey[800]!, colors),
          _colorRow('Phase B', 'Red', Colors.red, colors),
          _colorRow('Phase C', 'Blue', Colors.blue, colors),
          _colorRow('Neutral', 'White', Colors.white, colors),
          _colorRow('Ground', 'Green/Bare', Colors.green, colors),
          const SizedBox(height: 12),
          Text('277/480V:', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 6),
          _colorRow('Phase A', 'Brown', Colors.brown, colors),
          _colorRow('Phase B', 'Orange', Colors.orange, colors),
          _colorRow('Phase C', 'Yellow', Colors.yellow, colors),
          _colorRow('Neutral', 'Gray', Colors.grey, colors),
          _colorRow('Ground', 'Green/Bare', Colors.green, colors),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.accentWarning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              Icon(LucideIcons.alertTriangle, color: colors.accentWarning, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text('High-leg (wild leg) must be orange - NEC 110.15', style: TextStyle(color: colors.accentWarning, fontSize: 11))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _colorRow(String phase, String color, Color dotColor, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Container(width: 14, height: 14, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle, border: dotColor == Colors.white ? Border.all(color: colors.borderSubtle) : null)),
        const SizedBox(width: 10),
        SizedBox(width: 70, child: Text(phase, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
        Text(color, style: TextStyle(color: colors.textPrimary, fontSize: 12)),
      ]),
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
            Text('3-PHASE FORMULAS', style: TextStyle(color: colors.accentInfo, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          _formulaRow('Line-to-Line', 'V_LL = V_LN x 1.732', colors),
          _formulaRow('Line-to-Neutral', 'V_LN = V_LL / 1.732', colors),
          _formulaRow('3-Phase Power (kW)', 'P = V x I x 1.732 x PF / 1000', colors),
          _formulaRow('3-Phase Amps', 'I = kW x 1000 / (V x 1.732 x PF)', colors),
          _formulaRow('3-Phase kVA', 'kVA = V x I x 1.732 / 1000', colors),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Example:', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 11)),
                Text('480V, 100A, PF=0.9', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('kW = 480 x 100 x 1.732 x 0.9 / 1000 = 74.8 kW', style: TextStyle(color: colors.accentPrimary, fontFamily: 'monospace', fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _formulaRow(String name, String formula, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(name, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w500, fontSize: 12))),
          Expanded(child: Text(formula, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildPanelConfig(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('3-PHASE PANEL LAYOUT', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _panelLine('Circuit#   LEFT    RIGHT   Circuit#', colors.textTertiary),
                _panelLine('  1        A *----* A        2', colors.accentError),
                _panelLine('  3        B *----* B        4', colors.accentInfo),
                _panelLine('  5        C *----* C        6', colors.accentWarning),
                _panelLine('  7        A *----* A        8', colors.accentError),
                _panelLine('  9        B *----* B       10', colors.accentInfo),
                _panelLine(' 11        C *----* C       12', colors.accentWarning),
                _panelLine('         (pattern repeats)', colors.textTertiary),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text('Balance loads across all 3 phases', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          Text('3-pole breaker spans A-B-C', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          Text('2-pole breaker spans 2 phases', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _panelLine(String text, Color color) {
    return Text(text, style: TextStyle(color: color, fontFamily: 'monospace', fontSize: 10));
  }

  Widget _buildCodeReference(ZaftoColors colors) {
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
            Icon(LucideIcons.bookOpen, color: colors.accentInfo, size: 18),
            const SizedBox(width: 8),
            Text('NEC REFERENCE', style: TextStyle(color: colors.accentInfo, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Text(
            '• NEC 110.15 - High-Leg Marking\n'
            '• NEC 408.3 - Panelboard Requirements\n'
            '• NEC 210.4 - Multiwire Branch Circuits\n'
            '• NEC 220 - Branch Circuit and Feeder Calculations\n'
            '• NEC 430 - Motors, Motor Circuits',
            style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}
