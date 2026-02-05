import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Wire Pull Tension Calculator - Design System v2.6
/// Calculates maximum pulling force for conductors per NEC/ICEA standards
class WirePullTensionScreen extends ConsumerStatefulWidget {
  const WirePullTensionScreen({super.key});
  @override
  ConsumerState<WirePullTensionScreen> createState() => _WirePullTensionScreenState();
}

class _WirePullTensionScreenState extends ConsumerState<WirePullTensionScreen> {
  String _wireSize = '10';
  String _conductorMaterial = 'copper';
  int _conductorCount = 3;
  double _runLength = 100;
  double _frictionCoefficient = 0.5;
  bool _hasLubricant = true;

  // Maximum pulling tension per conductor (lbs) - based on ICEA standards
  static const Map<String, Map<String, double>> _maxTensionPerConductor = {
    'copper': {
      '14': 58, '12': 92, '10': 146, '8': 232, '6': 370,
      '4': 588, '3': 740, '2': 934, '1': 1178, '1/0': 1486,
      '2/0': 1872, '3/0': 2360, '4/0': 2976, '250': 3400,
      '300': 4080, '350': 4760, '400': 5440, '500': 6800,
    },
    'aluminum': {
      '14': 36, '12': 58, '10': 92, '8': 146, '6': 232,
      '4': 370, '3': 466, '2': 588, '1': 740, '1/0': 934,
      '2/0': 1178, '3/0': 1486, '4/0': 1872, '250': 2150,
      '300': 2580, '350': 3010, '400': 3440, '500': 4300,
    },
  };

  // Conductor weight per 1000 ft (lbs)
  static const Map<String, Map<String, double>> _conductorWeight = {
    'copper': {
      '14': 12.7, '12': 20.2, '10': 32.1, '8': 51.0, '6': 81.1,
      '4': 129, '3': 162, '2': 205, '1': 258, '1/0': 326,
      '2/0': 411, '3/0': 518, '4/0': 653, '250': 773,
      '300': 927, '350': 1082, '400': 1236, '500': 1545,
    },
    'aluminum': {
      '14': 3.9, '12': 6.2, '10': 9.8, '8': 15.6, '6': 24.8,
      '4': 39.4, '3': 49.7, '2': 62.7, '1': 79.0, '1/0': 99.6,
      '2/0': 126, '3/0': 158, '4/0': 200, '250': 236,
      '300': 284, '350': 331, '400': 378, '500': 473,
    },
  };

  static const List<String> _wireSizes = [
    '14', '12', '10', '8', '6', '4', '3', '2', '1',
    '1/0', '2/0', '3/0', '4/0', '250', '300', '350', '400', '500'
  ];

  double get _effectiveFriction => _hasLubricant ? _frictionCoefficient * 0.35 : _frictionCoefficient;

  double get _weightPerFoot {
    final weight = _conductorWeight[_conductorMaterial]?[_wireSize] ?? 0;
    return (weight / 1000) * _conductorCount;
  }

  double get _totalCableWeight => _weightPerFoot * _runLength;

  double get _maxTensionTotal {
    final perConductor = _maxTensionPerConductor[_conductorMaterial]?[_wireSize] ?? 0;
    return perConductor * _conductorCount;
  }

  double get _estimatedPullForce {
    // Simplified: Weight × Friction coefficient (horizontal pull)
    // Real pulls require bend multipliers
    return _totalCableWeight * _effectiveFriction;
  }

  double get _safetyMargin => _maxTensionTotal > 0 ? (_maxTensionTotal - _estimatedPullForce) / _maxTensionTotal * 100 : 0;

  bool get _isPullSafe => _estimatedPullForce < _maxTensionTotal * 0.8;

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Wire Pull Tension', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildWireSizeCard(colors),
          const SizedBox(height: 16),
          _buildMaterialCard(colors),
          const SizedBox(height: 16),
          _buildConductorCountCard(colors),
          const SizedBox(height: 16),
          _buildRunLengthCard(colors),
          const SizedBox(height: 16),
          _buildFrictionCard(colors),
          const SizedBox(height: 20),
          _buildResultsCard(colors),
          const SizedBox(height: 16),
          _buildCodeReference(colors),
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
          IconButton(onPressed: _conductorCount < 12 ? () { HapticFeedback.selectionClick(); setState(() => _conductorCount++); } : null, icon: Icon(LucideIcons.plusCircle, color: _conductorCount < 12 ? colors.accentPrimary : colors.textTertiary, size: 32)),
        ]),
        Center(child: Text('conductors in pull', style: TextStyle(color: colors.textTertiary, fontSize: 12))),
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
            child: Slider(value: _runLength, min: 25, max: 500, divisions: 19, onChanged: (v) { HapticFeedback.selectionClick(); setState(() => _runLength = v); }),
          )),
        ]),
      ]),
    );
  }

  Widget _buildFrictionCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('PULLING CONDITIONS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: Text('Using wire lubricant', style: TextStyle(color: colors.textSecondary, fontSize: 14))),
          Switch(
            value: _hasLubricant,
            onChanged: (v) { HapticFeedback.selectionClick(); setState(() => _hasLubricant = v); },
            activeColor: colors.accentPrimary,
          ),
        ]),
        const SizedBox(height: 8),
        Text(_hasLubricant ? 'Friction reduced by 65%' : 'No lubricant - higher friction', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _isPullSafe ? colors.accentPrimary.withValues(alpha: 0.2) : colors.accentError.withValues(alpha: 0.5)),
      ),
      child: Column(children: [
        Text('${_estimatedPullForce.toStringAsFixed(0)}', style: TextStyle(color: _isPullSafe ? colors.accentPrimary : colors.accentError, fontSize: 56, fontWeight: FontWeight.w700, letterSpacing: -2)),
        Text('lbs Estimated Pull Force', style: TextStyle(color: colors.textTertiary, fontSize: 14)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: _isPullSafe ? colors.accentSuccess.withValues(alpha: 0.2) : colors.accentError.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
          child: Text(_isPullSafe ? 'SAFE PULL' : 'EXCEEDS LIMIT', style: TextStyle(color: _isPullSafe ? colors.accentSuccess : colors.accentError, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(10)),
          child: Column(children: [
            _buildResultRow(colors, 'Max Tension (total)', '${_maxTensionTotal.toStringAsFixed(0)} lbs'),
            const SizedBox(height: 10),
            _buildResultRow(colors, 'Cable Weight', '${_totalCableWeight.toStringAsFixed(1)} lbs'),
            const SizedBox(height: 10),
            _buildResultRow(colors, 'Weight/ft', '${_weightPerFoot.toStringAsFixed(2)} lbs/ft'),
            const SizedBox(height: 10),
            _buildResultRow(colors, 'Effective Friction', _effectiveFriction.toStringAsFixed(2)),
            Divider(color: colors.borderSubtle, height: 20),
            _buildResultRow(colors, 'Safety Margin', '${_safetyMargin.toStringAsFixed(0)}%', highlight: true),
          ]),
        ),
      ]),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool highlight = false}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
      Text(value, style: TextStyle(color: highlight ? colors.accentPrimary : colors.textPrimary, fontSize: 13, fontWeight: highlight ? FontWeight.w600 : FontWeight.w500)),
    ]);
  }

  Widget _buildCodeReference(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(10)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(LucideIcons.scale, color: colors.textTertiary, size: 16), const SizedBox(width: 8), Text('ICEA / NEC Standards', style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600))]),
        const SizedBox(height: 8),
        Text('• ICEA P-32-382: Max tension guidelines\n• NEC 300.31: Pullbox sizing at bends\n• Use 80% of max tension as safe limit\n• Always use pulling lubricant for long runs', style: TextStyle(color: colors.textTertiary, fontSize: 11, height: 1.5)),
      ]),
    );
  }
}
