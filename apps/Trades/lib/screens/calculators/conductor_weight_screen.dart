import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Conductor Weight Calculator - Design System v2.6
/// Calculates weight for wire pulls and support spacing
class ConductorWeightScreen extends ConsumerStatefulWidget {
  const ConductorWeightScreen({super.key});
  @override
  ConsumerState<ConductorWeightScreen> createState() => _ConductorWeightScreenState();
}

class _ConductorWeightScreenState extends ConsumerState<ConductorWeightScreen> {
  String _wireSize = '10';
  String _conductorMaterial = 'copper';
  String _insulationType = 'THHN';
  int _conductorCount = 3;
  double _runLength = 100;

  // Bare conductor weight per 1000 ft (lbs)
  static const Map<String, Map<String, double>> _bareWeight = {
    'copper': {
      '14': 12.7, '12': 20.2, '10': 32.1, '8': 51.0, '6': 81.1,
      '4': 129, '3': 162, '2': 205, '1': 258, '1/0': 326,
      '2/0': 411, '3/0': 518, '4/0': 653, '250': 773,
      '300': 927, '350': 1082, '400': 1236, '500': 1545,
      '600': 1854, '750': 2318, '1000': 3090,
    },
    'aluminum': {
      '14': 3.9, '12': 6.2, '10': 9.8, '8': 15.6, '6': 24.8,
      '4': 39.4, '3': 49.7, '2': 62.7, '1': 79.0, '1/0': 99.6,
      '2/0': 126, '3/0': 158, '4/0': 200, '250': 236,
      '300': 284, '350': 331, '400': 378, '500': 473,
      '600': 567, '750': 709, '1000': 946,
    },
  };

  // Insulation weight multiplier (approximate)
  static const Map<String, double> _insulationMultiplier = {
    'THHN': 1.15,
    'THWN': 1.18,
    'XHHW': 1.20,
    'USE': 1.22,
    'MC': 1.45,
    'AC': 1.55,
    'NM': 1.35,
  };

  static const List<String> _wireSizes = [
    '14', '12', '10', '8', '6', '4', '3', '2', '1',
    '1/0', '2/0', '3/0', '4/0', '250', '300', '350', '400', '500', '600', '750', '1000'
  ];

  double get _bareWeightPer1000 => _bareWeight[_conductorMaterial]?[_wireSize] ?? 0;
  double get _insulatedWeightPer1000 => _bareWeightPer1000 * (_insulationMultiplier[_insulationType] ?? 1.15);
  double get _weightPerFoot => _insulatedWeightPer1000 / 1000;
  double get _totalWeightSingle => _weightPerFoot * _runLength;
  double get _totalWeightAll => _totalWeightSingle * _conductorCount;
  double get _weightPerMeter => _weightPerFoot * 3.281;
  double get _totalWeightKg => _totalWeightAll * 0.4536;

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Conductor Weight', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildWireSizeCard(colors),
          const SizedBox(height: 16),
          _buildMaterialCard(colors),
          const SizedBox(height: 16),
          _buildInsulationCard(colors),
          const SizedBox(height: 16),
          _buildConductorCountCard(colors),
          const SizedBox(height: 16),
          _buildRunLengthCard(colors),
          const SizedBox(height: 20),
          _buildResultsCard(colors),
          const SizedBox(height: 16),
          _buildWeightTableCard(colors),
        ],
      ),
    );
  }

  Widget _buildWireSizeCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('WIRE SIZE (AWG/kcmil)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: _wireSizes.take(12).map((size) {
          final isSelected = _wireSize == size;
          return GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); setState(() => _wireSize = size); },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgBase, borderRadius: BorderRadius.circular(8)),
              child: Text(size, style: TextStyle(color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
            ),
          );
        }).toList()),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: _wireSizes.skip(12).map((size) {
          final isSelected = _wireSize == size;
          return GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); setState(() => _wireSize = size); },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgBase, borderRadius: BorderRadius.circular(8)),
              child: Text(size, style: TextStyle(color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
            ),
          );
        }).toList()),
      ]),
    );
  }

  Widget _buildMaterialCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('CONDUCTOR MATERIAL', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); setState(() => _conductorMaterial = 'copper'); },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(color: _conductorMaterial == 'copper' ? colors.accentPrimary : colors.bgBase, borderRadius: BorderRadius.circular(8)),
              child: Center(child: Text('Copper', style: TextStyle(color: _conductorMaterial == 'copper' ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary, fontWeight: FontWeight.w500))),
            ),
          )),
          const SizedBox(width: 12),
          Expanded(child: GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); setState(() => _conductorMaterial = 'aluminum'); },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(color: _conductorMaterial == 'aluminum' ? colors.accentPrimary : colors.bgBase, borderRadius: BorderRadius.circular(8)),
              child: Center(child: Text('Aluminum', style: TextStyle(color: _conductorMaterial == 'aluminum' ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary, fontWeight: FontWeight.w500))),
            ),
          )),
        ]),
      ]),
    );
  }

  Widget _buildInsulationCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('INSULATION TYPE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: _insulationMultiplier.keys.map((type) {
          final isSelected = _insulationType == type;
          return GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); setState(() => _insulationType = type); },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgBase, borderRadius: BorderRadius.circular(8)),
              child: Text(type, style: TextStyle(color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
            ),
          );
        }).toList()),
      ]),
    );
  }

  Widget _buildConductorCountCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('NUMBER OF CONDUCTORS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          IconButton(onPressed: _conductorCount > 1 ? () { HapticFeedback.selectionClick(); setState(() => _conductorCount--); } : null, icon: Icon(LucideIcons.minusCircle, color: _conductorCount > 1 ? colors.accentPrimary : colors.textTertiary, size: 32)),
          const SizedBox(width: 20),
          Text('$_conductorCount', style: TextStyle(color: colors.textPrimary, fontSize: 48, fontWeight: FontWeight.w700)),
          const SizedBox(width: 20),
          IconButton(onPressed: _conductorCount < 20 ? () { HapticFeedback.selectionClick(); setState(() => _conductorCount++); } : null, icon: Icon(LucideIcons.plusCircle, color: _conductorCount < 20 ? colors.accentPrimary : colors.textTertiary, size: 32)),
        ]),
      ]),
    );
  }

  Widget _buildRunLengthCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('RUN LENGTH (feet)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 12),
        Row(children: [
          Text('${_runLength.toInt()} ft', style: TextStyle(color: colors.accentPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          Expanded(child: SliderTheme(
            data: SliderThemeData(activeTrackColor: colors.accentPrimary, inactiveTrackColor: colors.bgBase, thumbColor: colors.accentPrimary),
            child: Slider(value: _runLength, min: 10, max: 1000, divisions: 99, onChanged: (v) { HapticFeedback.selectionClick(); setState(() => _runLength = v); }),
          )),
        ]),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.2))),
      child: Column(children: [
        Text('${_totalWeightAll.toStringAsFixed(1)}', style: TextStyle(color: colors.accentPrimary, fontSize: 56, fontWeight: FontWeight.w700, letterSpacing: -2)),
        Text('lbs Total Weight', style: TextStyle(color: colors.textTertiary, fontSize: 14)),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(10)),
          child: Column(children: [
            _buildResultRow(colors, 'Weight per foot', '${_weightPerFoot.toStringAsFixed(3)} lbs'),
            const SizedBox(height: 10),
            _buildResultRow(colors, 'Weight per 1000ft', '${_insulatedWeightPer1000.toStringAsFixed(1)} lbs'),
            const SizedBox(height: 10),
            _buildResultRow(colors, 'Single conductor', '${_totalWeightSingle.toStringAsFixed(1)} lbs'),
            Divider(color: colors.borderSubtle, height: 20),
            _buildResultRow(colors, 'Total (metric)', '${_totalWeightKg.toStringAsFixed(1)} kg', highlight: true),
          ]),
        ),
      ]),
    );
  }

  Widget _buildWeightTableCard(ZaftoColors colors) {
    final commonSizes = ['14', '12', '10', '8', '6', '4', '2', '1/0', '4/0'];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('COPPER WEIGHT REFERENCE (lbs/1000ft)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 12),
        Wrap(spacing: 6, runSpacing: 6, children: commonSizes.map((size) {
          final weight = _bareWeight['copper']?[size] ?? 0;
          final isHighlighted = size == _wireSize;
          return Container(
            width: 70,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(color: isHighlighted ? colors.accentPrimary.withValues(alpha: 0.2) : colors.bgBase, borderRadius: BorderRadius.circular(6), border: isHighlighted ? Border.all(color: colors.accentPrimary) : null),
            child: Column(children: [
              Text(size, style: TextStyle(color: isHighlighted ? colors.accentPrimary : colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
              Text('${weight.toStringAsFixed(0)}', style: TextStyle(color: isHighlighted ? colors.accentPrimary : colors.textTertiary, fontSize: 10)),
            ]),
          );
        }).toList()),
      ]),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool highlight = false}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
      Text(value, style: TextStyle(color: highlight ? colors.accentPrimary : colors.textPrimary, fontSize: 13, fontWeight: highlight ? FontWeight.w600 : FontWeight.w500)),
    ]);
  }
}
