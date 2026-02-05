import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Capacitor Bank Calculator - Design System v2.6
/// Power factor correction capacitor sizing
class CapacitorBankScreen extends ConsumerStatefulWidget {
  const CapacitorBankScreen({super.key});
  @override
  ConsumerState<CapacitorBankScreen> createState() => _CapacitorBankScreenState();
}

class _CapacitorBankScreenState extends ConsumerState<CapacitorBankScreen> {
  double _loadKw = 100;
  double _currentPf = 0.75;
  double _targetPf = 0.95;
  int _voltage = 480;
  String _phase = 'three';

  double? _requiredKvar;
  double? _capacitorUf;
  double? _annualSavings;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // Calculate kVAR needed
    final currentAngle = math.acos(_currentPf);
    final targetAngle = math.acos(_targetPf);
    final currentKvar = _loadKw * math.tan(currentAngle);
    final targetKvar = _loadKw * math.tan(targetAngle);
    final requiredKvar = currentKvar - targetKvar;

    // Calculate capacitance (for reference)
    double capacitorUf;
    if (_phase == 'three') {
      capacitorUf = (requiredKvar * 1000000) / (2 * math.pi * 60 * _voltage * _voltage / 1000);
    } else {
      capacitorUf = (requiredKvar * 1000000) / (2 * math.pi * 60 * _voltage * _voltage / 1000);
    }

    // Estimate annual savings (rough - $0.02/kVAR-month penalty avoided)
    final annualSavings = requiredKvar * 0.02 * 12;

    String recommendation;
    if (requiredKvar < 10) {
      recommendation = 'Small correction needed. Consider fixed capacitors.';
    } else if (requiredKvar < 50) {
      recommendation = 'Moderate correction. Fixed bank with contactor recommended.';
    } else {
      recommendation = 'Large correction. Consider automatic capacitor bank with steps.';
    }

    setState(() {
      _requiredKvar = requiredKvar;
      _capacitorUf = capacitorUf;
      _annualSavings = annualSavings;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _loadKw = 100;
      _currentPf = 0.75;
      _targetPf = 0.95;
      _voltage = 480;
      _phase = 'three';
    });
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
        title: Text('Capacitor Bank', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'LOAD PARAMETERS'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Load Power', value: _loadKw, min: 10, max: 1000, unit: ' kW', onChanged: (v) { setState(() => _loadKw = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSegmentedToggle(colors, label: 'System Voltage', options: const ['208V', '240V', '480V', '600V'], selectedIndex: [208, 240, 480, 600].indexOf(_voltage), onChanged: (i) { setState(() => _voltage = [208, 240, 480, 600][i]); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'POWER FACTOR'),
              const SizedBox(height: 12),
              _buildPfSlider(colors, label: 'Current PF', value: _currentPf, onChanged: (v) { setState(() => _currentPf = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildPfSlider(colors, label: 'Target PF', value: _targetPf, onChanged: (v) { setState(() => _targetPf = v); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'CAPACITOR SIZING'),
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
        Icon(LucideIcons.battery, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('Size capacitors to improve power factor. Typical target: 0.95. Avoid overcorrection above 1.0.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildSliderRow(ZaftoColors colors, {required String label, required double value, required double min, required double max, required String unit, required ValueChanged<double> onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 14)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(8)),
            child: Text('${value.round()}$unit', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(activeTrackColor: colors.accentPrimary, inactiveTrackColor: colors.bgCard, thumbColor: colors.accentPrimary),
          child: Slider(value: value, min: min, max: max, onChanged: onChanged),
        ),
      ],
    );
  }

  Widget _buildPfSlider(ZaftoColors colors, {required String label, required double value, required ValueChanged<double> onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 14)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(8)),
            child: Text(value.toStringAsFixed(2), style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(activeTrackColor: colors.accentPrimary, inactiveTrackColor: colors.bgCard, thumbColor: colors.accentPrimary),
          child: Slider(value: value, min: 0.50, max: 0.99, onChanged: onChanged),
        ),
      ],
    );
  }

  Widget _buildSegmentedToggle(ZaftoColors colors, {required String label, required List<String> options, required int selectedIndex, required ValueChanged<int> onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 14)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(8)),
          child: Row(
            children: options.asMap().entries.map((e) {
              final selected = e.key == selectedIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(e.key),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(color: selected ? colors.accentPrimary : Colors.transparent, borderRadius: BorderRadius.circular(8)),
                    child: Center(child: Text(e.value, style: TextStyle(color: selected ? Colors.white : colors.textSecondary, fontWeight: FontWeight.w600, fontSize: 12))),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    if (_requiredKvar == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Text('${_requiredKvar!.toStringAsFixed(1)}', style: TextStyle(color: colors.textPrimary, fontSize: 48, fontWeight: FontWeight.w700)),
          Text('kVAR Required', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'PF Improvement', '${_currentPf.toStringAsFixed(2)} → ${_targetPf.toStringAsFixed(2)}')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Est. Annual Savings', '\$${_annualSavings?.toStringAsFixed(0)}')),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(LucideIcons.lightbulb, color: colors.accentWarning, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(_recommendation ?? '', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildResultItem(ZaftoColors colors, String label, String value) {
    return Column(children: [
      Text(value, style: TextStyle(color: colors.accentPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
    ]);
  }
}
