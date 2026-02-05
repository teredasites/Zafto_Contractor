import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Harmonics Calculator - Design System v2.6
/// THD and K-factor calculations for nonlinear loads
class HarmonicsScreen extends ConsumerStatefulWidget {
  const HarmonicsScreen({super.key});
  @override
  ConsumerState<HarmonicsScreen> createState() => _HarmonicsScreenState();
}

class _HarmonicsScreenState extends ConsumerState<HarmonicsScreen> {
  String _loadType = 'vfd';
  double _fundamentalCurrent = 100;
  double _third = 80;
  double _fifth = 60;
  double _seventh = 40;
  double _ninth = 20;

  double? _thd;
  double? _kFactor;
  double? _neutralCurrent;
  String? _transformerDerating;
  String? _recommendation;

  final Map<String, Map<String, double>> _typicalHarmonics = {
    'vfd': {'3rd': 25, '5th': 15, '7th': 10, '9th': 5},
    'ups': {'3rd': 30, '5th': 20, '7th': 12, '9th': 8},
    'computer': {'3rd': 80, '5th': 60, '7th': 35, '9th': 15},
    'led': {'3rd': 70, '5th': 50, '7th': 30, '9th': 10},
    'custom': {'3rd': 80, '5th': 60, '7th': 40, '9th': 20},
  };

  @override
  void initState() { super.initState(); _setTypicalValues(); _calculate(); }

  void _setTypicalValues() {
    final typical = _typicalHarmonics[_loadType]!;
    _third = typical['3rd']!;
    _fifth = typical['5th']!;
    _seventh = typical['7th']!;
    _ninth = typical['9th']!;
  }

  void _calculate() {
    // Convert percentages to per-unit
    final h3 = _third / 100;
    final h5 = _fifth / 100;
    final h7 = _seventh / 100;
    final h9 = _ninth / 100;

    // THD calculation
    final thd = math.sqrt(h3 * h3 + h5 * h5 + h7 * h7 + h9 * h9) * 100;

    // K-Factor calculation: K = Σ(Ih² × h²) / Σ(Ih²)
    final sumIhSq = 1 + h3 * h3 + h5 * h5 + h7 * h7 + h9 * h9;
    final sumIhSqHSq = 1 + (h3 * h3 * 9) + (h5 * h5 * 25) + (h7 * h7 * 49) + (h9 * h9 * 81);
    final kFactor = sumIhSqHSq / sumIhSq;

    // Neutral current (triplen harmonics add in neutral)
    final neutralCurrent = h3 * 3 * _fundamentalCurrent;

    // Transformer derating
    String derating;
    if (kFactor <= 4) {
      derating = 'Standard transformer OK';
    } else if (kFactor <= 13) {
      derating = 'K-13 rated transformer required';
    } else if (kFactor <= 20) {
      derating = 'K-20 rated transformer required';
    } else {
      derating = 'Special K-rated transformer needed';
    }

    String recommendation;
    if (thd > 20) {
      recommendation = 'High THD - consider harmonic filters or isolation transformer.';
    } else if (neutralCurrent > _fundamentalCurrent) {
      recommendation = 'Oversized neutral required due to triplen harmonics.';
    } else {
      recommendation = 'Harmonic levels acceptable for standard equipment.';
    }

    setState(() {
      _thd = thd;
      _kFactor = kFactor;
      _neutralCurrent = neutralCurrent;
      _transformerDerating = derating;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _loadType = 'vfd';
      _fundamentalCurrent = 100;
    });
    _setTypicalValues();
    _calculate();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Harmonics Calculator', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _reset, tooltip: 'Reset')],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInfoCard(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'LOAD TYPE'),
              const SizedBox(height: 12),
              _buildLoadTypeSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'HARMONIC CONTENT (% of Fundamental)'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: '3rd Harmonic', value: _third, max: 100, onChanged: (v) { setState(() { _third = v; _loadType = 'custom'; }); _calculate(); }),
              _buildSliderRow(colors, label: '5th Harmonic', value: _fifth, max: 80, onChanged: (v) { setState(() { _fifth = v; _loadType = 'custom'; }); _calculate(); }),
              _buildSliderRow(colors, label: '7th Harmonic', value: _seventh, max: 60, onChanged: (v) { setState(() { _seventh = v; _loadType = 'custom'; }); _calculate(); }),
              _buildSliderRow(colors, label: '9th Harmonic', value: _ninth, max: 40, onChanged: (v) { setState(() { _ninth = v; _loadType = 'custom'; }); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'ANALYSIS'),
              const SizedBox(height: 12),
              _buildResultCard(colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Row(children: [
        Icon(LucideIcons.activity, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('Calculate THD and K-factor for nonlinear loads like VFDs, UPS, computers, and LED lighting.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildLoadTypeSelector(ZaftoColors colors) {
    final types = [
      ('vfd', 'VFD'),
      ('ups', 'UPS'),
      ('computer', 'Computers'),
      ('led', 'LED'),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: types.map((t) {
        final selected = _loadType == t.$1;
        return GestureDetector(
          onTap: () { setState(() => _loadType = t.$1); _setTypicalValues(); _calculate(); },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? colors.accentPrimary : colors.bgCard,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
            ),
            child: Text(t.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSliderRow(ZaftoColors colors, {required String label, required double value, required double max, required ValueChanged<double> onChanged}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 14)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(6)),
              child: Text('${value.round()}%', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
            ),
          ]),
          const SizedBox(height: 6),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(activeTrackColor: colors.accentPrimary, inactiveTrackColor: colors.bgCard, thumbColor: colors.accentPrimary, overlayColor: colors.accentPrimary.withValues(alpha: 0.2), trackHeight: 4),
            child: Slider(value: value, min: 0, max: max, onChanged: onChanged),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    if (_thd == null) return const SizedBox.shrink();
    final highThd = _thd! > 20;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Row(children: [
            Expanded(child: _buildMetricCard(colors, 'THD', '${_thd!.toStringAsFixed(1)}%', highThd ? colors.accentWarning : colors.accentPositive)),
            const SizedBox(width: 12),
            Expanded(child: _buildMetricCard(colors, 'K-Factor', _kFactor!.toStringAsFixed(1), _kFactor! > 13 ? colors.accentWarning : colors.accentPositive)),
          ]),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_transformerDerating ?? '', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(_recommendation ?? '', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(ZaftoColors colors, String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Text(value, style: TextStyle(color: valueColor, fontSize: 28, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
      ]),
    );
  }
}
