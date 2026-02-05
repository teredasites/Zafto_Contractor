import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Fan Affinity Laws Calculator - Design System v2.6
/// Fan laws for speed, flow, pressure, and power
class FanAffinityScreen extends ConsumerStatefulWidget {
  const FanAffinityScreen({super.key});
  @override
  ConsumerState<FanAffinityScreen> createState() => _FanAffinityScreenState();
}

class _FanAffinityScreenState extends ConsumerState<FanAffinityScreen> {
  double _originalCfm = 1000;
  double _originalRpm = 1750;
  double _originalPressure = 2.0; // inches WC
  double _originalHp = 3.0;
  double _newRpm = 1500;
  String _calculationMode = 'speed';

  double? _newCfm;
  double? _newPressure;
  double? _newHp;
  double? _speedRatio;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // Fan Affinity Laws:
    // CFM2/CFM1 = RPM2/RPM1
    // P2/P1 = (RPM2/RPM1)²
    // HP2/HP1 = (RPM2/RPM1)³

    final speedRatio = _newRpm / _originalRpm;

    final newCfm = _originalCfm * speedRatio;
    final newPressure = _originalPressure * math.pow(speedRatio, 2);
    final newHp = _originalHp * math.pow(speedRatio, 3);

    String recommendation;
    recommendation = 'Speed ratio: ${speedRatio.toStringAsFixed(2)}. ';

    if (speedRatio < 1) {
      final energySaving = (1 - math.pow(speedRatio, 3)) * 100;
      recommendation += 'Reducing speed by ${((1 - speedRatio) * 100).toStringAsFixed(0)}% saves ${energySaving.toStringAsFixed(0)}% energy. ';
    } else {
      final energyIncrease = (math.pow(speedRatio, 3) - 1) * 100;
      recommendation += 'Increasing speed by ${((speedRatio - 1) * 100).toStringAsFixed(0)}% increases power by ${energyIncrease.toStringAsFixed(0)}%. ';
    }

    if (newHp > _originalHp * 1.15) {
      recommendation += 'WARNING: Motor may be overloaded at new speed. Verify motor HP capacity.';
    }

    recommendation += ' Fan laws assume no change in air density or system resistance curve.';

    if (speedRatio < 0.5) {
      recommendation += ' Very low speed: Check for surge and minimum flow requirements.';
    }

    if (_newRpm > 3600) {
      recommendation += ' High speed: Verify structural integrity and vibration limits.';
    }

    recommendation += ' VFD operation: Most efficient at 30-100% speed. Below 30% efficiency drops rapidly.';

    setState(() {
      _newCfm = newCfm;
      _newPressure = newPressure;
      _newHp = newHp;
      _speedRatio = speedRatio;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _originalCfm = 1000;
      _originalRpm = 1750;
      _originalPressure = 2.0;
      _originalHp = 3.0;
      _newRpm = 1500;
      _calculationMode = 'speed';
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
        title: Text('Fan Affinity Laws', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'ORIGINAL CONDITIONS'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'CFM', _originalCfm, 100, 10000, '', (v) { setState(() => _originalCfm = v); _calculate(); })),
                const SizedBox(width: 8),
                Expanded(child: _buildCompactSlider(colors, 'RPM', _originalRpm, 500, 3600, '', (v) { setState(() => _originalRpm = v); _calculate(); })),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'Pressure', _originalPressure, 0.5, 10, '" WC', (v) { setState(() => _originalPressure = v); _calculate(); }, decimals: 1)),
                const SizedBox(width: 8),
                Expanded(child: _buildCompactSlider(colors, 'HP', _originalHp, 0.5, 50, '', (v) { setState(() => _originalHp = v); _calculate(); }, decimals: 1)),
              ]),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'NEW SPEED'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'New RPM', value: _newRpm, min: 200, max: 3600, unit: ' RPM', onChanged: (v) { setState(() => _newRpm = v); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'NEW CONDITIONS'),
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
        Icon(LucideIcons.fan, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('Fan Laws: CFM ∝ RPM, Pressure ∝ RPM², Power ∝ RPM³. Reducing speed by 20% saves 49% power.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildCompactSlider(ZaftoColors colors, String label, double value, double min, double max, String unit, ValueChanged<double> onChanged, {int decimals = 0}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 12)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(6)),
          child: Text('${value.toStringAsFixed(decimals)}$unit', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(activeTrackColor: colors.accentPrimary, inactiveTrackColor: colors.bgCard, thumbColor: colors.accentPrimary, trackHeight: 3, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5)),
          child: Slider(value: value, min: min, max: max, onChanged: onChanged),
        ),
      ],
    );
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
            child: Text('${value.toStringAsFixed(0)}$unit', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600)),
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

  Widget _buildResultCard(ZaftoColors colors) {
    if (_newCfm == null) return const SizedBox.shrink();

    final speedRatio = _speedRatio ?? 1.0;
    final energyChange = (math.pow(speedRatio, 3) - 1) * 100;
    final isSaving = energyChange < 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isSaving ? Colors.green.withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(child: Text(
              isSaving ? '${energyChange.abs().toStringAsFixed(0)}% Energy Savings' : '${energyChange.toStringAsFixed(0)}% Energy Increase',
              style: TextStyle(color: isSaving ? Colors.green.shade700 : Colors.orange.shade700, fontSize: 16, fontWeight: FontWeight.w600),
            )),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: _buildComparisonItem(colors, 'CFM', _originalCfm.toStringAsFixed(0), _newCfm!.toStringAsFixed(0)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildComparisonItem(colors, 'Pressure', '${_originalPressure.toStringAsFixed(1)}"', '${_newPressure!.toStringAsFixed(2)}"'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildComparisonItem(colors, 'HP', _originalHp.toStringAsFixed(1), _newHp!.toStringAsFixed(2)),
            ),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Speed Ratio', '${speedRatio.toStringAsFixed(2)}×')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Original RPM', '${_originalRpm.toStringAsFixed(0)}')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'New RPM', '${_newRpm.toStringAsFixed(0)}')),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(LucideIcons.info, color: colors.textSecondary, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(_recommendation ?? '', style: TextStyle(color: colors.textSecondary, fontSize: 12))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonItem(ZaftoColors colors, String label, String original, String newValue) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
      child: Column(children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 10)),
        const SizedBox(height: 4),
        Text(original, style: TextStyle(color: colors.textPrimary.withValues(alpha: 0.5), fontSize: 12, decoration: TextDecoration.lineThrough)),
        Text(newValue, style: TextStyle(color: colors.accentPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _buildResultItem(ZaftoColors colors, String label, String value) {
    return Column(children: [
      Text(value, style: TextStyle(color: colors.accentPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 10)),
    ]);
  }
}
