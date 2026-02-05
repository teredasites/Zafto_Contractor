import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Transformer Impedance Calculator - Design System v2.6
/// Calculate fault current contribution from transformer %Z
class TransformerImpedanceScreen extends ConsumerStatefulWidget {
  const TransformerImpedanceScreen({super.key});
  @override
  ConsumerState<TransformerImpedanceScreen> createState() => _TransformerImpedanceScreenState();
}

class _TransformerImpedanceScreenState extends ConsumerState<TransformerImpedanceScreen> {
  double _kva = 75;
  double _impedancePercent = 5.75;
  int _secondaryVoltage = 208;
  bool _threePhase = true;

  double? _secondaryFla;
  double? _maxFaultCurrent;
  double? _letThroughEnergy;
  String? _aicrRecommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Transformer %Z', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'TRANSFORMER'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'kVA Rating', value: _kva, min: 15, max: 2500, unit: ' kVA', onChanged: (v) { setState(() => _kva = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Impedance (%Z)', value: _impedancePercent, min: 1.5, max: 10, unit: '%', isDecimal: true, onChanged: (v) { setState(() => _impedancePercent = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSegmentedToggle(colors, label: 'Secondary Voltage', options: const ['120/240', '208Y/120', '480Y/277'], selectedIndex: _secondaryVoltage == 240 ? 0 : _secondaryVoltage == 208 ? 1 : 2, onChanged: (i) { setState(() => _secondaryVoltage = [240, 208, 480][i]); _calculate(); }),
              const SizedBox(height: 12),
              _buildSegmentedToggle(colors, label: 'Phase', options: const ['1Ø', '3Ø'], selectedIndex: _threePhase ? 1 : 0, onChanged: (i) { setState(() => _threePhase = i == 1); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'FAULT CURRENT'),
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
        Icon(LucideIcons.info, color: colors.accentPrimary, size: 24),
        const SizedBox(width: 12),
        Expanded(child: Text('Max fault current = FLA ÷ (%Z / 100)', style: TextStyle(color: colors.accentPrimary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) => Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2));

  Widget _buildSliderRow(ZaftoColors colors, {required String label, required double value, required double min, required double max, required String unit, bool isDecimal = false, required ValueChanged<double> onChanged}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          Text('${isDecimal ? value.toStringAsFixed(2) : value.toStringAsFixed(0)}$unit', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 16)),
        ]),
        SliderTheme(
          data: SliderThemeData(activeTrackColor: colors.accentPrimary, inactiveTrackColor: colors.borderSubtle, thumbColor: colors.accentPrimary, overlayColor: colors.accentPrimary.withValues(alpha: 0.2)),
          child: Slider(value: value, min: min, max: max, divisions: isDecimal ? ((max - min) * 4).round() : (max - min).round(), onChanged: onChanged),
        ),
      ]),
    );
  }

  Widget _buildSegmentedToggle(ZaftoColors colors, {required String label, required List<String> options, required int selectedIndex, required ValueChanged<int> onChanged}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        const SizedBox(height: 12),
        Row(children: List.generate(options.length, (i) => Expanded(
          child: GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); onChanged(i); },
            child: Container(
              margin: EdgeInsets.only(right: i < options.length - 1 ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(color: selectedIndex == i ? colors.accentPrimary : colors.bgBase, borderRadius: BorderRadius.circular(8), border: Border.all(color: selectedIndex == i ? colors.accentPrimary : colors.borderSubtle)),
              alignment: Alignment.center,
              child: Text(options[i], style: TextStyle(color: selectedIndex == i ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary, fontWeight: FontWeight.w600, fontSize: 12)),
            ),
          ),
        ))),
      ]),
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3), width: 1.5)),
      child: Column(children: [
        Text('${(_maxFaultCurrent ?? 0) > 1000 ? ((_maxFaultCurrent ?? 0) / 1000).toStringAsFixed(1) : (_maxFaultCurrent ?? 0).toStringAsFixed(0)}', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w700, fontSize: 48)),
        Text((_maxFaultCurrent ?? 0) > 1000 ? 'kA available fault current' : 'A available fault current', style: TextStyle(color: colors.textTertiary, fontSize: 14)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: colors.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(_aicrRecommendation ?? '10 kAIC minimum', style: TextStyle(color: colors.warning, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 20),
        Divider(color: colors.borderSubtle),
        const SizedBox(height: 16),
        _buildCalcRow(colors, 'Transformer', '${_kva.toStringAsFixed(0)} kVA @ ${_impedancePercent.toStringAsFixed(2)}%Z'),
        _buildCalcRow(colors, 'Secondary FLA', '${_secondaryFla?.toStringAsFixed(1) ?? '0'} A'),
        _buildCalcRow(colors, 'Multiplier (100/%Z)', '${(100 / _impedancePercent).toStringAsFixed(1)}×'),
        const SizedBox(height: 8),
        Divider(color: colors.borderSubtle),
        const SizedBox(height: 8),
        _buildCalcRow(colors, 'Max fault current', '${_maxFaultCurrent?.toStringAsFixed(0) ?? '0'} A', highlight: true),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('NOTE', style: TextStyle(color: colors.warning, fontSize: 11, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('This is maximum theoretical fault current assuming infinite utility. Actual fault current depends on utility available fault current.', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildCalcRow(ZaftoColors colors, String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Expanded(child: Text(label, style: TextStyle(color: highlight ? colors.textPrimary : colors.textSecondary, fontSize: 13))),
        Text(value, style: TextStyle(color: highlight ? colors.accentPrimary : colors.textPrimary, fontWeight: highlight ? FontWeight.w700 : FontWeight.w600, fontSize: 14)),
      ]),
    );
  }

  void _calculate() {
    // Calculate secondary FLA
    double fla;
    if (_threePhase) {
      fla = (_kva * 1000) / (_secondaryVoltage * 1.732);
    } else {
      fla = (_kva * 1000) / _secondaryVoltage;
    }

    // Maximum fault current = FLA / (%Z/100)
    // This assumes infinite primary (utility) fault current
    final maxFault = fla / (_impedancePercent / 100);

    // Recommend AIC rating
    String aicRec;
    if (maxFault <= 10000) {
      aicRec = '10 kAIC minimum';
    } else if (maxFault <= 14000) {
      aicRec = '14 kAIC minimum';
    } else if (maxFault <= 18000) {
      aicRec = '18 kAIC minimum';
    } else if (maxFault <= 22000) {
      aicRec = '22 kAIC minimum';
    } else if (maxFault <= 25000) {
      aicRec = '25 kAIC minimum';
    } else if (maxFault <= 35000) {
      aicRec = '35 kAIC minimum';
    } else if (maxFault <= 42000) {
      aicRec = '42 kAIC minimum';
    } else if (maxFault <= 65000) {
      aicRec = '65 kAIC minimum';
    } else {
      aicRec = '100 kAIC+ required';
    }

    setState(() {
      _secondaryFla = fla;
      _maxFaultCurrent = maxFault;
      _aicrRecommendation = aicRec;
    });
  }

  void _reset() {
    setState(() {
      _kva = 75;
      _impedancePercent = 5.75;
      _secondaryVoltage = 208;
      _threePhase = true;
    });
    _calculate();
  }
}
